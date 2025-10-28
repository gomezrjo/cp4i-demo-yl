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
	PrintLn "Syntax: 30a-mailpit-deploy-mail-server.sh [-h]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy MailPit instance." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################

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

PrintLn "Creating mailpit namespace..." "BLUE"
oc new-project mailpit &>/dev/null
echo "project/mailpit created"

# This script requires the oc command being installed in your environment
PrintLn "Generating mailpit-admin password..." "BLUE"

if [ "$MSYSTEM" != "MINGW64" ]; then
  MAILPIT_ADMIN_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-');
else
  # Windows git bash doesn't have uuidgen in some cases
  MAILPIT_ADMIN_PWD=$(powershell -Command '[guid]::NewGuid().ToString()' | tr '[:upper:]' '[:lower:]' | tr -d '-');
fi;

PrintLn "Preparing mailpit deployment manifest..." "BLUE"
( echo "cat <<EOF" ; cat resources/30a-mailpit-deployment.yaml ;) | \
  MAILPIT_ADMIN_PWD=${MAILPIT_ADMIN_PWD} \
  sh > mailpit-deployment.yaml

PrintLn "Deploying mailpit server..." "BLUE"
oc apply -f mailpit-deployment.yaml

PrintLn "Waiting for mailpit server to be ready..." "BLUE"
while ! oc wait --for=jsonpath='{.status.conditions[0].status}'=True \
      deployment/mailpit -n mailpit 2>/dev/null; do 
	sleep 5
done

PrintLn "Creating mailpit services and route..." "BLUE"
oc apply -f resources/30b-mailpit-services.yaml 
oc apply -f resources/30c-mailpit-route.yaml

MAILPIT_URL=$(oc get route mailpit-ui -n mailpit -o jsonpath='{.status.ingress[0].host}')
PrintLn "MailPit URL is: http://${MAILPIT_URL}" "CYAN"
PrintLn "Password for mailpit-admin is: ${MAILPIT_ADMIN_PWD}" "CYAN"
PrintLn "INFO: Write down this information to access MailPit later on once it is ready." "YELLOW"
PressEnter

PrintLn "Cleaning up temp files..." "BLUE"
rm -f mailpit-deployment.yaml

PrintLn "Done! MailPit has been deployed..." "GREEN"