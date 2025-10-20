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
	PrintLn "Syntax: 08b-event-streams-initial-config.sh [-h|n|i]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide ES Namespace value." "CYAN"
	PrintLn "   i     Provide ES Instance name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Configure Event Streams instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME='es-demo'
NS_NAME='tools'

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:i:h"
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
ValidateOpDeployed "eventstreams"
ValidateInstance "$INST_NAME" "EventStreams" "$NS_NAME"
PressEnter

################################
# INITIAL EVENT STREAMS CONFIG #
################################

PrintLn "Preparing resources manifests..." "BLUE"
( echo "cat <<EOF" ; cat resources/02a-es-initial-config-jgr-topics.yaml ;) | \
	INST_NAME=${INST_NAME} \
	sh > es-initial-config-jgr-topics.yaml
( echo "cat <<EOF" ; cat resources/02a-es-initial-config-jgr-users.yaml ;) | \
	INST_NAME=${INST_NAME} \
	sh > es-initial-config-jgr-users.yaml
( echo "cat <<EOF" ; cat resources/02a-es-initial-config-ea-topics.yaml ;) | \
	INST_NAME=${INST_NAME} \
	sh > es-initial-config-ea-topics.yaml
( echo "cat <<EOF" ; cat resources/02a-es-initial-config-watsonx-topics.yaml ;) | \
	INST_NAME=${INST_NAME} \
	sh > es-initial-config-watsonx-topics.yaml
PrintLn "Defining topics and users..." "BLUE"
oc apply -f es-initial-config-jgr-topics.yaml -n $NS_NAME
oc apply -f es-initial-config-ea-topics.yaml -n $NS_NAME
oc apply -f es-initial-config-watsonx-topics.yaml -n $NS_NAME
if [[ -z "$(oc get eventstreams $INST_NAME -n $NS_NAME -o jsonpath='{.status.kafkaListeners[?(@.name=="plain")].bootstrapServers}')" ]]; then
	oc apply -f es-initial-config-jgr-users.yaml -n $NS_NAME
else
	PrintLn "Skipping users due to plain security..." "BLUE"
fi
PrintLn "Cleaning up temp files..." "BLUE"
rm -f es-initial-config-jgr-topics.yaml
rm -f es-initial-config-jgr-users.yaml
rm -f es-initial-config-ea-topics.yaml
rm -f es-initial-config-watsonx-topics.yaml
PrintLn "Event Streams instance $INST_NAME in namespace $NS_NAME has been configured." "GREEN"