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
	PrintLn "Syntax: 35b-dp-gw-inst-deploy.sh [-h|n|i|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide DP Gateway Namespace value." "CYAN"
	PrintLn "   i     Provide DP Gateway Instance name." "CYAN"
	PrintLn "   s     Enable Save Manifest." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy DataPower Gateway instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="dp-demo"
NS_NAME="cp4i-dp"
SAVE_MANIFEST="NO"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:sh"
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
ValidateOpDeployed "datapower"
PressEnter

PrintLn "Creating DataPower Gateway configuration..." "BLUE"
oc apply -f resources/16a-dp-gw-webui-config.yaml -n ${NS_NAME}
if [[ -z "$(oc get secret admin-secret -n ${NS_NAME} --no-headers --ignore-not-found=true)" ]]; then
	oc -n ${NS_NAME} create secret generic admin-secret --from-literal=password=admin
else
	PrintLn "DP Gateway admin-secret already exists in namespace $NS_NAME" "GREEN"
fi

PrintLn "Getting info from CSV..." "BLUE"
SUB_NAME=$(oc get deployment datapower-operator -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
INST_VER=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "DataPowerService")] | .[] | select(.metadata.name == "quickstart") | .spec.version')
INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "DataPowerService")] | .[] | select(.metadata.name == "quickstart") | .spec.license.license')

PrintLn "Preparing instance manifest..." "BLUE"
( echo "cat <<EOF" ; cat instances/common/24-dp-gwy-instance.yaml ;) | \
	INST_NAME=${INST_NAME} \
	INST_VER=${INST_VER} \
	INST_LIC=${INST_LIC} \
	sh > dp-gwy-instance.yaml

PrintLn "Deploying DataPower Gateway instance $INST_NAME..." "BLUE"
oc apply -f dp-gwy-instance.yaml -n ${NS_NAME}

PrintLn "Cleaning up temp files..." "BLUE"
if [ $SAVE_MANIFEST == "YES" ]; then
	SaveManifest "dp-gwy-instance"
fi
rm -f dp-gwy-instance.yaml

PrintLn "Done! Check progress..." "GREEN"
