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
    PrintLn "   apic" "YELLOW"
	PrintLn "Syntax: 07i-apic-secret-cp4i-apikey.sh [-h|n|i|e|d|k]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide CP4I Namespace value." "CYAN"
	PrintLn "   i     Provide CP4I Instance name." "CYAN"
    PrintLn "   e     Provide APIC Namespace value." "CYAN"
    PrintLn "   d     Provide APIC Instance name." "CYAN"
    PrintLn "   k     Provide APIC API Key value." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Build API Secret for Assembly" "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
CP4I_INST_NAME='cp4i-navigator'
CP4I_NAMESPACE='tools'
API_KEY="$APIC_API_KEY"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:e:d:k:h"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # Display Help
			Help
			exit;;
		n) # Update namespace value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			CP4I_NAMESPACE=$OPTARG;;
		i) # Update instance value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			CP4I_INST_NAME=$OPTARG;;
		e) # Update namespace value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			APIC_NAMESPACE=$OPTARG;;
		d) # Update instance value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			APIC_INST_NAME=$OPTARG;;
		k) # Update api key value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			API_KEY=$OPTARG;;
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
ValidateAWK
ValidateOC
ValidateAPIKey "$API_KEY"
ValidateNS "$CP4I_NAMESPACE" "NOKEY"
ValidateOpDeployed "cp4i"
ValidateInstance "$CP4I_INST_NAME" "PlatformNavigator" "$CP4I_NAMESPACE"
ValidateNS "$APIC_NAMESPACE" "NOKEY" "EXTRA"
ValidateOpDeployed "datapower"
ValidateOpDeployed "apiconnect"
ValidateInstance "$APIC_INST_NAME" "APIConnectCluster" "$APIC_NAMESPACE"
ValidateAPICcli "$APIC_INST_NAME" "$APIC_NAMESPACE"
PressEnter

#################
# CREATE SECRET #
#################
PrintLn "Preparing secret manifest..." "BLUE"
APIC_FULL_BASE_URL=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n ${APIC_NAMESPACE} -o jsonpath='{.status.endpoints[?(@.name=="platformApi")].uri}')
APIC_BASE_URL=$(echo ${APIC_FULL_BASE_URL%/*})
PrintLn "APIC BASE URL: $APIC_BASE_URL" "CYAN"
APIC_SECRET_NAME=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n ${APIC_NAMESPACE} -o jsonpath='{.status.endpoints[?(@.name=="platformApi")].secretName}')
oc extract secret/${APIC_SECRET_NAME} -n ${APIC_NAMESPACE} --keys=ca.crt
APIC_TRUSTED_CERT=`awk '{print "    "$0}' ca.crt`
( echo "cat <<EOF" ; cat templates/template-cp4i-apic-secret-v2.yaml ;) | \
    APIC_BASE_URL=${APIC_BASE_URL} \
    APIC_API_KEY=${API_KEY} \
    APIC_TRUSTED_CERT=${APIC_TRUSTED_CERT} \
    sh > cp4i-apic-secret.yaml

PrintLn "Creating Secret..." "BLUE"
oc apply -f cp4i-apic-secret.yaml -n ${CP4I_NAMESPACE}

PrintLn "Cleaning up temp files..." "BLUE"
rm -f ca.crt
rm -f cp4i-apic-secret.yaml

PrintLn "API Secret for Assembly has been created" "GREEN"