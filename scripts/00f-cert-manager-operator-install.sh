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
	PrintLn "Syntax: 00f-cert-manager-operator-install.sh [-h]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy Cert Manager Operator." "YELLOW"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":h"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # display Help
			Help
			exit;;
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
PressEnter

PrintLn "Creating Namespace..." "BLUE"
oc apply -f resources/00-cert-manager-namespace.yaml

PrintLn "Creating Operator Group..." "BLUE"
oc apply -f resources/00-cert-manager-operatorgroup.yaml

PrintLn "Creating Subscription..." "BLUE"
oc apply -f resources/00-cert-manager-subscription.yaml

PrintLn "Done! Check progress..." "GREEN"
