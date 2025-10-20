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
	PrintLn "Syntax: 99-setup-image-registry.sh [-h]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Set Up Image Registry in OCP." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":k:h"
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

if [[ -z "$(oc get pod -n openshift-image-registry -l docker-registry=default --ignore-not-found --no-headers)" ]]; then
    PrintLn "Image Registry instance is NOT available" "MAGENTA"
    if [[ "$(oc get clusteroperator image-registry --ignore-not-found --no-headers | awk '{print $3}')" == "True" ]]; then
        PrintLn "Image Registry operator is available" "YELLOW"
        PrintLn "Patching Image Registry configuration" "BLUE"
        oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"managementState":"Managed"}}'
        oc patch config.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}'
        PrintLn "Creating PVC for Image Registry" "BLUE"
        oc create -f resources/99-image-registry-pvc.yaml -n openshift-image-registry
        PrintLn "Deploying Image Registry instance" "BLUE"
        oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"storage":{"pvc":{"claim":"image-registry-storage"}}}}'
        while ! oc wait --for=jsonpath='{.status.conditions[1].status}'=True deployment/image-registry -n openshift-image-registry 2>/dev/null; do sleep 30; done
        PrintLn "Image Registry instance is ready" "GREEN"
    else
        PrintLn "Image Registry operator is NOT available" "RED"
    fi
else
    PrintLn "Image Registry instance is available" "GREEN"
fi