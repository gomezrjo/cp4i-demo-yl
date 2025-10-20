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
	PrintLn "Syntax: 19b-eem-gateway-inst-deploy.sh [-h|n|i|d|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide EEM Namespace value." "CYAN"
	PrintLn "   i     Provide Event Gateway Instance name." "CYAN"
    PrintLn "   d     Provide EEM Instance name." "CYAN"
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
INST_NAME='eem-demo-gw'
NS_NAME='tools'
SAVE_MANIFEST="NO"
EEM_INST_NAME='eem-demo-mgr'

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:d:sh"
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
		d) # Update dependency instance name
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			EEM_INST_NAME=$OPTARG;;
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
ValidateNS "$NS_NAME"
ValidateOpDeployed "eem"
ValidateInstance "$EEM_INST_NAME" "EventEndpointManagement" "$NS_NAME"
PressEnter

PrintLn "Getting info from CSV..." "BLUE"
SUB_NAME=$(oc get deployment ibm-eem-operator -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
#INST_VER=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "EventGateway")] | .[] | select(.metadata.name == "quick-start-gw") | .spec.version')
INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "EventGateway")] | .[] | select(.metadata.name == "quick-start-gw") | .spec.license.license')

PrintLn "Preparing instance manifest..." "BLUE"
EEM_GATEWAY_ROUTE=$(oc get route "${EEM_INST_NAME}-ibm-eem-gateway" -n $NS_NAME -o jsonpath="{.spec.host}")
( echo "cat <<EOF" ; cat instances/common/20-eem-gateway-instance.yaml ;) | \
    INST_NAME=${INST_NAME} \
    INST_LIC=${INST_LIC} \
    EEM_GATEWAY_ROUTE=${EEM_GATEWAY_ROUTE} \
    sh > eem-gateway-instance.yaml

PrintLn "Deploying Event Endpoint Manager instance $INST_NAME..." "BLUE"
oc apply -f eem-gateway-instance.yaml -n ${NS_NAME}

PrintLn "Cleaning up temp files..." "BLUE"
if [ $SAVE_MANIFEST == "YES" ]; then
	SaveManifest "eem-gateway-instance"
fi
rm -f eem-gateway-instance.yaml

PrintLn "Done! Check progress..." "GREEN"