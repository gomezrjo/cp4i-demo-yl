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
	PrintLn "Syntax: 00e-cp4i-ckeck-operator-deploy.sh [-h|n|o]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide CP4I Namespace value." "CYAN"
	PrintLn "   o     Provide CP4I Short Operator name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Check CP4I Operators deployment." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
NS_NAME="openshift-operators"
OP_NAME=""

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:o:h"
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
		o) # Get operator name
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			OP_NAME=$OPTARG;;
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
if [ -z "$OP_NAME" ]; then
  PrintLn "ERROR: -o (operator name) is a mandatory argument." "RED"
  Help
  exit 1
fi

#PrintLn "Checking pre-requisites..." "BLUE"
ValidateOC
ValidateOpName "$OP_NAME"
ValidateNS "$NS_NAME" "NOKEY"
#PressEnter

SUB_NAME=$(oc get deployment "${DEPLOYMENTS[$OP_IND]}" -n $NS_NAME --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')

if [ ! -z "$SUB_NAME" ]; then 
	SUB_STATUS=$(oc get csv/$SUB_NAME --ignore-not-found -n $NS_NAME -o jsonpath='{.status.phase}')
	if [ ! -z "$SUB_STATUS" ]; then
		PrintLn "$SUB_STATUS" "YELLOW"
	else
		PrintLn "Operator not ready yet. Wait few seconds and try again..." "MAGENTA"
	fi
else 
	PrintLn "Operator not ready yet. Wait few seconds and try again..." "MAGENTA"
fi