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
	PrintLn "Syntax: 03b-cp4i-access-info.sh [-h|n|i]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide CP4I Namespace value." "CYAN"
	PrintLn "   i     Provide CP4I Instance name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Get Platform UI access information." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="cp4i-navigator"
NS_NAME="tools"

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
ValidateOpDeployed "cp4i"
ValidateInstance "$INST_NAME" "PlatformNavigator" "$NS_NAME"
PressEnter

PrintLn "Getting Platform UI instance $INST_NAME access info..." "BLUE"
CP4I_URL=$(oc get platformnavigator ${INST_NAME} -n ${NS_NAME} -o jsonpath='{.status.endpoints[?(@.name=="navigator")].uri}') 
CP4I_USER=$(oc get secret integration-admin-initial-temporary-credentials -n ibm-common-services -o jsonpath={.data.username} | base64 -d)
CP4I_PWD=$(oc get secret integration-admin-initial-temporary-credentials -n ibm-common-services -o jsonpath={.data.password} | base64 -d)
PrintLn "CP4I Platform UI URL: $CP4I_URL" "YELLOW"
PrintLn "CP4I admin user: $CP4I_USER" "YELLOW"
PrintLn "CP4I admin password: $CP4I_PWD" "YELLOW"