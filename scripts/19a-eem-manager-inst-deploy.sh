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
	PrintLn "Syntax: 19a-eem-manager-inst-deploy.sh [-h|b|t|n|i|a|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   b     Provide SC Name directly." "CYAN"
    PrintLn "   t     Provide SC Type (ODF | TZEXT | ROKS)." "CYAN"
	PrintLn "   n     Provide ES Namespace value." "CYAN"
	PrintLn "   i     Provide ES Instance name." "CYAN"
	PrintLn "   a     Provide Authorization type (LOCAL | OIDC)." "CYAN"
	PrintLn "   s     Enable Save Manifest." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy Event Endpoint Manager instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
if [ -z "$OCP_TYPE" ]; then
    SC_TYPE="TZEXT"
else
    SC_TYPE=$OCP_TYPE
fi
if [ -z "$EA_OIDC" ]; then
    AUTH_TYPE="LOCAL"
else
    AUTH_TYPE="OIDC"
fi
INST_NAME='eem-demo-mgr'
NS_NAME='tools'
OCP_BLOCK_STORAGE=""
SC_NAME=""
SAVE_MANIFEST="NO"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:t:b:i:a:sh"
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
		a) # Update auth type
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			AUTH_TYPE=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]');;
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
ValidateOC
ValidateAuth "$AUTH_TYPE"
ValidateNS "$NS_NAME"
ValidateSC "$SC_TYPE" "$SC_NAME"
ValidateOpDeployed "eem"
PressEnter

###################
# INPUT VARIABLES #
###################

PrintLn "Getting info from CSV..." "BLUE"
SUB_NAME=$(oc get deployment ibm-eem-operator -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
#INST_VER=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "EventEndpointManagement")] | .[] | select(.metadata.name == "quick-start-manager") | .spec.version')
INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "EventEndpointManagement")] | .[] | select(.metadata.name == "quick-start-manager") | .spec.license.license')

PrintLn "Preparing instance manifest..." "BLUE"
cp instances/common/19-eem-manager-instance.yaml .
if [ "$AUTH_TYPE" == "LOCAL" ]; then
    PrintLn "Deploying EEM Manager instance with local security..." "BLUE"
    EEM_AUTH_TYPE='LOCAL'
else
    PrintLn "Deploying EEM Manager instance with OIDC security..." "BLUE"
    EEM_AUTH_TYPE='INTEGRATION_KEYCLOAK'
    yq -i '.spec.manager.template.pod.spec.containers[0].env[1].name = "EI_AUTH_OAUTH2_ADDITIONAL_SCOPES" | 
        .spec.manager.template.pod.spec.containers[0].env[1].value = "email,profile,offline_access" | 
        .spec.manager.template.pod.spec.containers[0].env[1].value style="single"' 19-eem-manager-instance.yaml
fi
( echo "cat <<EOF" ; cat 19-eem-manager-instance.yaml ;) | \
    INST_NAME=${INST_NAME} \
	INST_LIC=${INST_LIC} \
    EEM_AUTH_TYPE=${EEM_AUTH_TYPE} \
    OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
    sh > eem-manager-instance.yaml

PrintLn "Deploying Event Endpoint Manager instance $INST_NAME..." "BLUE"
oc apply -f eem-manager-instance.yaml -n ${NS_NAME}

PrintLn "Cleaning up temp files..." "BLUE"
if [ $SAVE_MANIFEST == "YES" ]; then
	SaveManifest "eem-manager-instance"
fi
rm -f 19-eem-manager-instance.yaml
rm -f eem-manager-instance.yaml

PrintLn "Done! Check progress..." "GREEN"