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
	PrintLn "Syntax: 00e-cp4i-ckeck-instance-deploy.sh [-h|n|i|c]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide CP4I Namespace value." "CYAN"
	PrintLn "   i     Provide CP4I Instance name." "CYAN"
	PrintLn "   c     Provide CP4I Capability name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Check CP4I Capability instance deployment." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
NS_NAME="tools"
INST_NAME=""
INST_TYPE=""

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:c:h"
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
		c) # Get capability type
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			INST_TYPE=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]');;
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

# Check for mandatory arguments
if [ -z "$INST_NAME" ]; then
  PrintLn "ERROR: -i (instance name) is a mandatory argument." "RED"
  Help
  exit 1
fi
if [ -z "$INST_TYPE" ]; then
  PrintLn "ERROR: -c (capability type) is a mandatory argument." "RED"
  Help
  exit 1
fi

#PrintLn "Checking pre-requisites..." "BLUE"
ValidateOC
ValidateNS "$NS_NAME" "NOKEY"
ValidateInstType "$INST_TYPE"
#PressEnter

if [[ -z "$(oc get ${INST_TYPE} ${INST_NAME} -n ${NS_NAME} --ignore-not-found --no-headers)" ]]; then
	PrintLn "ERROR: Instance $INST_NAME is not installed in namespace $NS_NAME. Check and try again." "RED"
	exit 1
fi

case "$INST_TYPE" in
	"platformnavigator")
		INST_STATUS=$(oc get ${INST_TYPE} ${INST_NAME} -n ${NS_NAME} -o jsonpath='{.status.conditions[0].type}')
		;;
	"kafkaconnect" | "kafkabridge")
		INST_STATUS=$(oc get ${INST_TYPE} ${INST_NAME} -n ${NS_NAME} -o jsonpath='{.status.conditions[0].type}')
		;;
	*)
		INST_STATUS=$(oc get ${INST_TYPE} ${INST_NAME} -n ${NS_NAME} -o jsonpath='{.status.phase}')
		;;
esac

PrintLn "$INST_STATUS" "YELLOW"