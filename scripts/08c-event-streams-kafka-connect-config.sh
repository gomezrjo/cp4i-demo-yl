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
	PrintLn "Syntax: 08c-event-streams-kafka-connect-config.sh [-h|n|i|d|u|s]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   i     Provide Kafka Connect Instance name." "CYAN"
	PrintLn "   n     Provide ES & KC Namespace value." "CYAN"
	PrintLn "   d     Provide ES Instance name." "CYAN"
    PrintLn "   u     Provide ES User name." "CYAN"
    PrintLn "   s     Enable Save Manifest." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy Kafka Connect instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="jgr-connect-cluster"
NS_NAME="tools"
ES_INST_NAME="es-demo"
ES_USER="kafka-connect-user"
SAVE_MANIFEST="NO"

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:d:u:sh"
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
		d) # Update instance value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			ES_INST_NAME=$OPTARG;;
		i) # Update instance value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			INST_NAME=$OPTARG;;
		u) # Update user value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			ES_USER=$OPTARG;;
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
ValidateOpDeployed "eventstreams"
ValidateInstance "$ES_INST_NAME" "EventStreams" "$NS_NAME"

###################################
# EVENT STREAMS CONFIG VALIDATION #
###################################
PrintLn "Validating ES Configuration..." "BLUE"
if [[ -z "$(oc get kafkauser $ES_USER -n $NS_NAME --no-headers --ignore-not-found)" ]]; then
    PrintLn "ERROR: User $ES_USER is not defined in ES instance $ES_INST_NAME in namespace $NS_NAME. Check and try again." "RED"
    exit 1
fi

PrintLn "Getting Bootstrap information..." "BLUE"
ES_BOOTSTRAP_SERVER=$(oc get eventstreams $ES_INST_NAME -n $NS_NAME -o jsonpath='{.status.kafkaListeners[?(@.name=="authsslsvc")].bootstrapServers}')
if [[ -z "${ES_BOOTSTRAP_SERVER}" ]]; then
    PrintLn "ERROR: ES instance $ES_INST_NAME in namespace $NS_NAME doesn't include the right Listener. Check and try again." "RED"
    exit 1
fi

PressEnter

PrintLn "Getting info from CSV..." "BLUE"
SUB_NAME=$(oc get deployment eventstreams-cluster-operator -n openshift-operators -o jsonpath='{.metadata.labels.olm\.owner}')
ES_VERSION=$(oc get csv/$SUB_NAME -o json | jq -r '.spec.version')

PrintLn "Updating template with Bootstrap info..." "BLUE"
( echo "cat <<EOF" ; cat templates/template-es-kafka-connect.yaml ;) | \
    INST_NAME=${INST_NAME} \
    ES_INST_NAME=${ES_INST_NAME} \
    ES_BOOTSTRAP_SERVER=${ES_BOOTSTRAP_SERVER} \
    ES_VERSION=${ES_VERSION} \
    ES_USER=${ES_USER} \
    sh > es-kafka-connect.yaml

PrintLn "Creating Kafka Connect instance..." "BLUE"
oc apply -f es-kafka-connect.yaml -n $NS_NAME

echo "Cleaning up temp files..."
if [ $SAVE_MANIFEST == "YES" ]; then
	SaveManifest "es-kafka-connect"
fi
rm -f es-kafka-connect.yaml

PrintLn "Done! Check progress..." "GREEN"