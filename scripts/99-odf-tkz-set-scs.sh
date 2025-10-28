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
	PrintLn "Syntax: 99-odf-tkz-set-scs.sh [-h|b|t]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   b     Provide SC Name directly." "CYAN"
    PrintLn "   t     Provide SC Type (ODF | TZEXT | ROKS)." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Set default storage class." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
if [ -z "$OCP_TYPE" ]; then
    SC_TYPE="TZEXT"
else
    SC_TYPE=$OCP_TYPE
fi
OCP_BLOCK_STORAGE=""
SC_NAME=""

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":b:t:h"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # display Help
			Help
			exit;;
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
ValidateSC "$SC_TYPE" "$SC_NAME"
PressEnter

PrintLn "Removing existing default storage class if any..." "BLUE"
if [ $(oc get sc | grep default | wc -l) -gt 0 ]; then
    oc get sc | grep default | awk '{system("oc patch storageclass " $1 " --patch-file resources/99-sc-remove-default.yaml")}'
fi

PrintLn "Setting default storage class..." "BLUE"
oc patch storageclass $OCP_BLOCK_STORAGE --patch-file resources/99-sc-set-default.yaml