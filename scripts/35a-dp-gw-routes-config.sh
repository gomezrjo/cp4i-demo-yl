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
	PrintLn "Syntax: 35a-dp-gw-routes-config.sh [-h|n|i]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide DP Gateway Namespace value." "CYAN"
	PrintLn "   i     Provide DP Gateway Instance name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Create DataPower Gateway Networking Configuration." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="dp-demo"
NS_NAME="cp4i-dp"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:h"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # display Help
			Help
			exit;;
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
ValidateNS "$NS_NAME" "NOKEY"
ValidateOpDeployed "datapower"
ValidateInstance "$INST_NAME" "DataPowerService" "$NS_NAME"
PressEnter

############################################
# CREATE SERVICE FOR STANDALONE DP GATEWAY #
############################################
PrintLn "Preparing Route File for DataPower Gateway WebUI..." "BLUE"
( echo "cat <<EOF" ; cat resources/16b-dp-gw-services.yaml ;) | \
    INST_NAME=${INST_NAME} \
    NS_NAME=${NS_NAME} \
    sh > dp-gw-services.yaml
PrintLn "Creating DataPower Gateway service to expose ports..." "BLUE"
oc apply -f dp-gw-services.yaml -n ${NS_NAME}

###########################################
# CREATE ROUTES FOR STANDALONE DP GATEWAY #
###########################################
PrintLn "Preparing Route File for DataPower Gateway WebUI..." "BLUE"
STACK_HOST="apps."$(oc get dnses.config.openshift.io cluster -o jsonpath='{.spec.baseDomain}')
( echo "cat <<EOF" ; cat templates/template-dp-gw-webui-route.yaml ;) | \
    INST_NAME=${INST_NAME} \
    NS_NAME=${NS_NAME} \
    STACK_HOST=${STACK_HOST} \
    sh > dp-webui-route.yaml

PrintLn "Creating DataPower WebUI Route..." "BLUE"
oc apply -f dp-webui-route.yaml -n ${NS_NAME}

PrintLn "Preparing Route File for DataPower Gateway HTTP User Traffic..." "BLUE"
( echo "cat <<EOF" ; cat templates/template-dp-gw-http-route.yaml ;) | \
    INST_NAME=${INST_NAME} \
    NS_NAME=${NS_NAME} \
    STACK_HOST=${STACK_HOST} \
    sh > dp-http-route.yaml

PrintLn "Creating DataPower Gateway HTTP Route..." "BLUE"
oc apply -f dp-http-route.yaml -n ${NS_NAME}

DPWEBUI_URL=$(oc get route dpwebui-route -n ${NS_NAME} -o jsonpath='{.spec.host}')
DP_ADMIN_PWD=$(oc get secret admin-secret -n ${NS_NAME} -o jsonpath='{.data.password}' | base64 -d)
PrintLn "DP Web UI URL is: https://${DPWEBUI_URL}" "CYAN"
PrintLn "Password for admin is: ${DP_ADMIN_PWD}" "CYAN"
PrintLn "INFO: Write down this information to access the DP Gateway later on." "YELLOW"
PressEnter

PrintLn "Cleaning up temp files..." "BLUE"
rm -f dp-gw-services.yaml
rm -f dp-webui-route.yaml
rm -f dp-http-route.yaml

PrintLn "DataPower Gateway Networking configuration (Service and Routes) has been created." "GREEN"

echo -e "\033[1;33mhttps://$(oc get route dpwebui-route -n cp4i-dp -o jsonpath='{.spec.host}')\033[0m"