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
	PrintLn "Syntax: 05-asset-repo-inst-deploy.sh [-h|b|t|n|i|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   b     Provide SC Name directly." "CYAN"
    PrintLn "   t     Provide SC Type (ODF | TZEXT | ROKS)." "CYAN"
	PrintLn "   n     Provide Asset Repo Namespace value." "CYAN"
	PrintLn "   i     Provide Asset Repo Instance name." "CYAN"
	PrintLn "   s     Enable Save Manifest." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy Asset Repository instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
if [ -z "$OCP_TYPE" ]; then
    SC_TYPE="TZEXT"
else
    SC_TYPE=$OCP_TYPE
fi
INST_NAME="asset-repo-ai"
NS_NAME="tools"
OCP_BLOCK_STORAGE=""
SC_NAME=""
SAVE_MANIFEST="NO"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:t:b:i:sh"
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
ValidateNS "$NS_NAME" 
ValidateSC "$SC_TYPE" "$SC_NAME"
ValidateOpDeployed "asset-repo"
PressEnter

PrintLn "Getting info from CSV..." "BLUE"
SUB_NAME=$(oc get deployment ibm-integration-asset-repository-operator -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
INST_VER=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "AssetRepository")] | .[] | select(.metadata.name == "fixed-single") | .spec.version')
INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "AssetRepository")] | .[] | select(.metadata.name == "fixed-single") | .spec.license.license')

PrintLn "Preparing instance manifest..." "BLUE"
( echo "cat <<EOF" ; cat instances/common/02-asset-repo-ai-instance.yaml ;) | \
	INST_NAME=${INST_NAME} \
	INST_LIC=${INST_LIC} \
	INST_VER=${INST_VER} \
	OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
	sh > asset-repo-instance.yaml

PrintLn "Deploying Asset Repository instance $INST_NAME..." "BLUE"
oc apply -f asset-repo-instance.yaml -n ${NS_NAME}

PrintLn "Cleaning up temp files..." "BLUE"
if [ $SAVE_MANIFEST == "YES" ]; then
	SaveManifest "asset-repo-instance"
fi
rm -f asset-repo-instance.yaml

PrintLn "Done! Check progress..." "GREEN"
