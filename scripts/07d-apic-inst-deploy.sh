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
	PrintLn "Syntax: 07d-apic-inst-deploy.sh [-h|b|t|n|i|x|z|m|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   b     Provide SC Name directly." "CYAN"
    PrintLn "   t     Provide SC Type (ODF | TZEXT | ROKS)." "CYAN"
	PrintLn "   n     Provide APIC Namespace value." "CYAN"
	PrintLn "   i     Provide APIC Instance name." "CYAN"
	PrintLn "   x     Enable Tracing." "CYAN"
	PrintLn "   z     Enable DP Image Override." "CYAN"
	PrintLn "   m     Provide Deployment mode (STD | POT)." "CYAN"
	PrintLn "   s     Enable Save Manifest." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy API Connect instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
if [ -z "$OCP_TYPE" ]; then
    SC_TYPE="TZEXT"
else
    SC_TYPE=$OCP_TYPE
fi
INST_NAME="apim-demo"
NS_NAME="tools"
OCP_BLOCK_STORAGE=""
SC_NAME=""
XTRC=$CP4I_TRACING
INST_PROFILE="n1xc7.m48"
DEP_MODE="STD"
SAVE_MANIFEST="NO"
OVERRIDE_DP=""

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:t:b:i:m:sxzh"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # Display Help
			Help
			exit;;
		x) # Enable Tracing
			PrintLn "INFO: Tracing enabled" "YELLOW"
			XTRC="YES";;
		z) # Enable Tracing
			PrintLn "INFO: Tracing enabled" "YELLOW"
			OVERRIDE_DP="YES";;
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
ValidateNS "$NS_NAME" 
ValidateSC "$SC_TYPE" "$SC_NAME"
ValidateOpDeployed "datapower"
ValidateOpDeployed "apiconnect"
PressEnter

PrintLn "Getting info from CSV..." "BLUE"
SUB_NAME=$(oc get deployment ibm-apiconnect -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
INST_VER=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "APIConnectCluster")] | .[] | select(.metadata.name == "small") | .spec.version')
INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "APIConnectCluster")] | .[] | select(.metadata.name == "small") | .spec.license.license')

PrintLn "Preparing instance manifest..." "BLUE"
if [ "$DEP_MODE" == "POT" ]; then
	INST_PROFILE="n1xc16.m72"
fi 
( echo "cat <<EOF" ; cat instances/common/04-apic-instance.yaml ;) | \
	INST_NAME=${INST_NAME} \
	INST_LIC=${INST_LIC} \
	INST_VER=${INST_VER} \
	INST_PROFILE=${INST_PROFILE} \
	OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
	sh > apic-instance.yaml
if [ "$DEP_MODE" == "STD" ]; then
	yq -i '.spec.management.billing.enabled = true |
		.spec.gateway.podAutoScaling.method = "HPA" |
		.spec.gateway.podAutoScaling.hpa.minReplicas = 1 |
		.spec.gateway.podAutoScaling.hpa.maxReplicas = 3 |
		.spec.gateway.podAutoScaling.hpa.targetCPUUtilizationPercentage = 50' apic-instance.yaml
fi 

if [ ! -z "$OVERRIDE_DP" ]; then
	PrintLn "Configuring DataPower override for APIC instance..." "BLUE"
	IMG_VER=""
	SUB_NAME=$(oc get deployment datapower-operator -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
	LISTVER=$(oc get csv $SUB_NAME -o json | jq -rc '.spec.customresourcedefinitions.owned | [.[] | select(.kind == "DataPowerService")] | .[] | .specDescriptors |  [.[] | select(.path == "version")] | .[] | ."x-descriptors"[]')
	while read i; do
		TEMPSTR="${i##*:}"
		if [[ "$TEMPSTR" > "$IMG_VER" ]]; then
			IMG_VER="$TEMPSTR"
		fi
	done < <(echo "$LISTVER")
	IMG_NAME="datapower-cp4i-$IMG_VER"
	IMG_SHA256=$(oc get csv $SUB_NAME -o json | jq --arg img_name $IMG_NAME -r '.spec.relatedImages | [.[] | select(.name == $img_name)] | .[] | .image')
	#IMG_VER=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "DataPowerService")] | .[] | select(.metadata.name == "quickstart") | .spec.version')
	IMG_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | [.[] | select(.kind == "DataPowerService")] | .[] | select(.metadata.name == "quickstart") | .spec.license.license')
	export IMG_VER
	export IMG_SHA256
	export IMG_LIC
	yq -i '.spec.gateway.dataPowerOverride.version = strenv(IMG_VER) |
		.spec.gateway.dataPowerOverride.license = strenv(IMG_LIC) |
		.spec.gateway.dataPowerOverride.image = strenv(IMG_SHA256)' apic-instance.yaml
fi

if [ ! -z "$XTRC" ]; then
    PrintLn "Configuring Tracing for APIC instance..." "BLUE"
    PrintLn "Work in progress..." "GREEN"
fi

PrintLn "Deploying API Connect instance $INST_NAME..." "BLUE"
oc apply -f apic-instance.yaml -n ${NS_NAME}

PrintLn "Cleaning up temp files..." "BLUE"
if [ $SAVE_MANIFEST == "YES" ]; then
	SaveManifest "apic-instance"
fi
rm -f apic-instance.yaml

PrintLn "Done! Check progress..." "GREEN"