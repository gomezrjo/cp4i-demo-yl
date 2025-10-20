#!/bin/bash
source ./scripts/00-cp4i-functions.sh

############################################################
# Help                                                     #
############################################################
Help()
{
	# Display Help
	PrintLn "This script requires the following utilities installed in your workstation:" "MAGENTA"
	PrintLn "   oc" "YELLOW"
	PrintLn "Syntax: 08a-event-streams-inst-deploy.sh [-h|b|t|n|i|m|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   b     Provide SC Name directly." "CYAN"
    PrintLn "   t     Provide SC Type (ODF | TZEXT | ROKS)." "CYAN"
	PrintLn "   n     Provide ES Namespace value." "CYAN"
	PrintLn "   i     Provide ES Instance name." "CYAN"
	PrintLn "   m     Provide Deployment mode (STD | B2B)." "CYAN"
	PrintLn "   s     Enable Save Manifest." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy Event Streams instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
if [ -z "$OCP_TYPE" ]; then
    SC_TYPE="TZEXT"
else
    SC_TYPE=$OCP_TYPE
fi
INST_NAME='es-demo'
NS_NAME='tools'
OCP_BLOCK_STORAGE=""
SC_NAME=""
DEP_MODE="STD"
SAVE_MANIFEST="NO"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:t:b:i:m:sh"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # Display Help
			Help
			exit;;
		s) # Enable save manifest
			PrintLn "INFO: Save Manifest enabled" "YELLOW"
			SAVE_MANIFEST="YES";;
		n) # Update namespace value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			NS_NAME=$OPTARG;;
		i) # Update instance value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			INST_NAME=$OPTARG;;
		t) # Update type value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			SC_TYPE=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]');;
		b) # Update storage class name
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			SC_NAME=$OPTARG;;
		m) # Update deployment mode
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			DEP_MODE=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]');;
		:) # 
			PrintLn "ERROR: Option -$OPTARG requires an argument." "RED"
			Help
			exit 1;;
	  	?) # Invalid option
			PrintLn "ERROR: Invalid option: -$OPTARG" "RED"
			Help
			exit 1;;
    	*) #
      		PrintLn "ERROR: This should not happen." "RED"
			Help
      		exit 1;;
	esac
done

PrintLn "Checking pre-requisites..." "BLUE"
ValidateYQ
ValidateOC
ValidateDepMode2 "$DEP_MODE"
ValidateNS "$NS_NAME"
ValidateSC "$SC_TYPE" "$SC_NAME"
ValidateOpDeployed "eventstreams"
PressEnter

PrintLn "Getting info from CSV..." "BLUE"
SUB_NAME=$(oc get deployment "${DEPLOYMENTS[$OP_IND]}" -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
if [ $DEP_MODE == "STD" ]; then
	INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "EventStreams")] | .[] | select(.metadata.name == "light-insec") | .spec.license.license')
	INST_USE=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "EventStreams")] | .[] | select(.metadata.name == "light-insec") | .spec.license.use')
else
	INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "EventStreams")] | .[] | select(.metadata.name == "light-insecure") | .spec.license.license')
	INST_USE=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "EventStreams")] | .[] | select(.metadata.name == "light-insecure") | .spec.license.use')
fi

PrintLn "Preparing instance manifest..." "BLUE"
( echo "cat <<EOF" ; cat instances/common/05-event-streams-instance.yaml ;) | \
	INST_NAME=${INST_NAME} \
	INST_LIC=${INST_LIC} \
	INST_USE=${INST_USE} \
    OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
    sh > event-streams-instance.yaml

if [ $DEP_MODE == "STD" ]; then
	yq -i '.metadata.labels."assembly.integration.ibm.com/tools.jgr-demo" = "true" |
		.metadata.labels."assembly.integration.ibm.com/tools.jgr-demo" style="single" |
		.spec.adminUI += {"authentication": [{"type": "integrationKeycloak"}]} |
		.spec.strimziOverrides.kafka.authorization.type = "simple" |
		.spec.strimziOverrides.kafka += {"listeners": [{"name": "authsslsvc", "port": 9095, "type": "internal", "tls": true, "authentication": {"type": "scram-sha-512"}}]} |
		.spec.strimziOverrides.kafka.listeners += {"name": "external", "port": 9094, "type": "route", "tls": true, "authentication": {"type": "scram-sha-512"}} |
		.spec.strimziOverrides.kafka.listeners += {"name": "tls", "port": 9093, "type": "internal", "tls": true, "authentication": {"type": "tls"}}' event-streams-instance.yaml
else
	yq -i '.spec.adminUI = {} |
		  .spec.security.internalTls = "NONE" |
		  .spec.strimziOverrides.kafka += {"listeners": [{"name": "plain", "port": 9092, "type": "internal", "tls": false}]}' event-streams-instance.yaml
fi


PrintLn "Deploying Event Streams instance $INST_NAME..." "BLUE"
oc apply -f event-streams-instance.yaml -n ${NS_NAME}

PrintLn "Cleaning up temp files..." "BLUE"
if [ $SAVE_MANIFEST == "YES" ]; then
	SaveManifest "event-streams-instance"
fi
rm -f event-streams-instance.yaml

PrintLn "Done! Check progress..." "GREEN"