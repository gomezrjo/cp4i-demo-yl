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
	PrintLn "Syntax: 07g-apic-extra-dp-info.sh [-h|n|i]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide API Gateway Namespace value." "CYAN"
	PrintLn "   i     Provide API Gateway Instance name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Get Extra API Gateway information." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="remote-api-gw"
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
ValidateOpDeployed "apiconnect"
ValidateInstance "$INST_NAME" "GatewayCluster" "$NS_NAME"
PressEnter

PrintLn "Getting API Gateway info..." "BLUE"
API_GTWY_MGR=$(oc get route $INST_NAME-gateway-manager -n $NS_NAME -o jsonpath='{.spec.host}')
API_GTWY_EP=$(oc get route $INST_NAME-gateway -n $NS_NAME -o jsonpath='{.spec.host}')

PrintLn "API Gateway Service info:" "YELLOW"
PrintLn "Management Endpoint URL: https://$API_GTWY_MGR" "YELLOW"
PrintLn "API Endpoint Base URL: https://$API_GTWY_EP" "YELLOW"
