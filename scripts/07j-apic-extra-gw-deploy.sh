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
	PrintLn "   jq" "YELLOW"
    PrintLn "   yq" "YELLOW"
	PrintLn "Syntax: 07j-apic-extra-gw-deploy.sh [-h|n|i|e|d|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide API Gateway Namespace value." "CYAN"
	PrintLn "   i     Provide API Gateway Instance name." "CYAN"
	PrintLn "   e     Provide APIC Namespace value." "CYAN"
	PrintLn "   d     Provide APIC Instance name." "CYAN"
	PrintLn "   s     Enable Save Manifest." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy Extra API Gateway instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="remote-api-gw"
NS_NAME="cp4i-dp"
DINST_NAME="apim-demo"
DNS_NAME="tools"
SAVE_MANIFEST="NO"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:e:d:sh"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # Display Help
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
		e) # Update namespace value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			DNS_NAME=$OPTARG;;
		d) # Update instance value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			DINST_NAME=$OPTARG;;
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
ValidateYQ
ValidateJQ
ValidateOC
ValidateNS "$NS_NAME" 
ValidateOpDeployed "datapower"
ValidateOpDeployed "apiconnect"
ValidateNS "$DNS_NAME" "NOKEY" "EXTRA"
ValidateInstance "$DINST_NAME" "APIConnectCluster" "$DNS_NAME"
PressEnter

############################
# DEPLOY EXTRA API GATEWAY #
############################
PrintLn "Preparing APIC ingress CA..." "BLUE"
oc -n "${DNS_NAME}" get secret "${DINST_NAME}-ingress-ca" -o yaml > ingress-ca.yaml
yq -i 'del(.metadata.creationTimestamp, .metadata.namespace, .metadata.resourceVersion, .metadata.uid, .metadata.selfLink)' \
        ingress-ca.yaml
oc apply -f ingress-ca.yaml -n ${NS_NAME}

PrintLn "Defining resources..." "BLUE"
oc apply -f resources/13a-apic-dp-selfsigning-issuer.yaml -n ${NS_NAME}
oc apply -f resources/13b-apic-dp-ingress-issuer.yaml -n ${NS_NAME}
oc apply -f resources/13c-apic-dp-gw-service-certificate.yaml -n ${NS_NAME}
oc apply -f resources/13d-apic-dp-gw-peering-certificate.yaml -n ${NS_NAME}
if [[ -z "$(oc get secret admin-secret -n ${NS_NAME} --no-headers --ignore-not-found=true)" ]]; then
	oc -n ${NS_NAME} create secret generic admin-secret --from-literal=password=admin
else
	PrintLn "DP Gateway admin-secret already exists in namespace $NS_NAME" "GREEN"
fi

PrintLn "Getting info from CSV..." "BLUE"
SUB_NAME=$(oc get deployment ibm-apiconnect -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
INST_VER=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | .[] | select(.kind == "GatewayCluster") | .spec.version')
INST_LIC=$(oc get csv $SUB_NAME -o json | jq -r '.metadata.annotations."alm-examples" | fromjson | .[] | select(.kind == "GatewayCluster") | .spec.license.license')

PrintLn "Preparing YAML file..." "BLUE"
STACK_HOST=$(oc get route "${DINST_NAME}-gw-gateway" -n ${DNS_NAME} -o jsonpath="{.spec.host}" | cut -d'.' -f2-)
( echo "cat <<EOF" ; cat instances/common/23-apic-api-gwy-instance.yaml ;) | \
    INST_NAME=${INST_NAME} \
	INST_VER=${INST_VER} \
	INST_LIC=${INST_LIC} \
    DINST_NAME=${DINST_NAME} \
    STACK_HOST=${STACK_HOST} \
    sh > apic-api-gwy-instance.yaml

PrintLn "Creating API Gateway instance..." "BLUE"
oc apply -f apic-api-gwy-instance.yaml -n ${NS_NAME}

PrintLn "Cleaning up temp files..." "BLUE"
if [ $SAVE_MANIFEST == "YES" ]; then
	SaveManifest "apic-api-gwy-instance"
fi
rm -f apic-api-gwy-instance.yaml
rm -f ingress-ca.yaml

PrintLn "Done! Check progress..." "GREEN"
