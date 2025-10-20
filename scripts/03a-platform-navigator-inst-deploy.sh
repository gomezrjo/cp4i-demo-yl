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
	PrintLn "Syntax: 03a-platform-navigator-inst-deploy.sh [-h|n|i|m|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide CP4I Namespace value." "CYAN"
	PrintLn "   i     Provide CP4I Instance name." "CYAN"
	PrintLn "   m     Provide Deployment mode (STD | POT)." "CYAN"
	PrintLn "   s     Enable Save Manifest." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy Platform UI instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="cp4i-navigator"
NS_NAME="tools"
INST_REP="1"
DEP_MODE="STD"
SAVE_MANIFEST="NO"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:m:sh"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # display Help
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
		m) # Update deployment mode
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			DEP_MODE=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]');;
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
ValidateJQ
ValidateOC
ValidateDepMode1 "$DEP_MODE"
ValidateNS "$NS_NAME"
ValidateOpDeployed "cp4i"
PressEnter

DEFAULT_SC=$(oc get sc -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
if [ ! -z "$DEFAULT_SC" ]; then
	PrintLn "INFO: Default Storage Class is set to $DEFAULT_SC" "YELLOW"
	PrintLn "Setting number of replicas..." "BLUE"
	if [ "$DEP_MODE" == "POT" ]; then
		INST_REP="3"
	fi 
	PrintLn "Getting info from CSV..." "BLUE"
	SUB_NAME=$(oc get deployment ibm-integration-platform-navigator-operator -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
	INST_VER=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "PlatformNavigator")] | .[] | select(.metadata.name == "integration-quickstart") | .spec.version')
	INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "PlatformNavigator")] | .[] | select(.metadata.name == "integration-quickstart") | .spec.license.license')
	PrintLn "Preparing instance manifest..." "BLUE"
	( echo "cat <<EOF" ; cat instances/common/01-platform-navigator-instance.yaml ;) | \
		INST_NAME=${INST_NAME} \
		INST_LIC=${INST_LIC} \
		INST_VER=${INST_VER} \
		INST_REP=${INST_REP} \
		sh > platform-nav-instance.yaml
	
	PrintLn "Deploying Platform UI instance $INST_NAME..." "BLUE"
	oc apply -f platform-nav-instance.yaml -n ${NS_NAME}

	PrintLn "Cleaning up temp files..." "BLUE"
	if [ $SAVE_MANIFEST == "YES" ]; then
		SaveManifest "platform-nav-instance"
	fi
	rm -f platform-nav-instance.yaml

	PrintLn "Done! Check progress..." "GREEN"
else
	PrintLn "ERROR: NO Default Storage Class has been set in your OCP Cluster. Check your cluster and try again." "RED"
fi