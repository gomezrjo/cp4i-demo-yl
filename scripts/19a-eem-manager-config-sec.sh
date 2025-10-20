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
	PrintLn "Syntax: 19a-eem-manager-config-sec.sh [-h|n|i]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide EEM Namespace value." "CYAN"
    PrintLn "   i     Provide EEM Instance name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Configure Event Endpoint Manager instance security." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME='eem-demo-mgr'
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
ValidateOpDeployed "eem"
ValidateInstance "$INST_NAME" "EventEndpointManagement" "$NS_NAME"
PressEnter

PrintLn "Checking EEM Manager instance security type..." "BLUE"
AUTH_TYPE=$(oc get eventendpointmanagement $INST_NAME -n $NS_NAME -o jsonpath='{.spec.manager.authConfig.authType}')

PrintLn "Configuring EEM Manager security..." "BLUE"
if [ "$AUTH_TYPE" == "LOCAL" ]; then
    PrintLn "Using local security..." "BLUE"
    if [ "$MSYSTEM" != "MINGW64" ]; then
        EEM_ADMIN_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
        EEM_USER_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
    else
        # Windows git bash doesn't have uuidgen in some cases
        EEM_ADMIN_PWD=$(powershell -Command '[guid]::NewGuid().ToString()' | tr '[:upper:]' '[:lower:]' | tr -d '-')
        EEM_USER_PWD=$(powershell -Command '[guid]::NewGuid().ToString()' | tr '[:upper:]' '[:lower:]' | tr -d '-')
    fi;
    (echo "cat <<EOF" ; cat templates/template-eem-user-credentials.json ;) | \
        EEM_ADMIN_PWD=${EEM_ADMIN_PWD} \
        EEM_USER_PWD=${EEM_USER_PWD} \
        sh > eem-user-credentials.json
    SECRET_DATA_BASE64=$(base64 -i eem-user-credentials.json | tr -d '\n')
    oc patch secret ${INST_NAME}-ibm-eem-user-credentials -n $NS_NAME --patch '{"data":{"user-credentials.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
    SECRET_DATA_BASE64=$(base64 -i resources/10-eem-user-roles.json | tr -d '\n')
    oc patch secret ${INST_NAME}-ibm-eem-user-roles -n $NS_NAME --patch '{"data":{"user-mapping.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
    PrintLn "Cleaning up temp files..." "BLUE"
    rm -f eem-user-credentials.json
    PrintLn "Password for eem-admin is: ${EEM_ADMIN_PWD}" "YELLOW"
    PrintLn "Password for eem-user is: ${EEM_USER_PWD}" "YELLOW"
    PrintLn "Write down the passwords" "CYAN"
    PressEnter
else
    PrintLn "Using OIDC security..." "BLUE"
    oc patch IntegrationKeycloakClient ${INST_NAME}-ibm-eem-keycloak -n $NS_NAME --patch '{"spec":{"client":{"optionalClientScopes":["offline_access"]}}}' --type=merge
fi

PrintLn "EEM Manager instance security has been configured" "GREEN"