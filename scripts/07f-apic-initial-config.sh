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
    PrintLn "   yq" "YELLOW"
    PrintLn "   apic" "YELLOW"
	PrintLn "Syntax: 07f-apic-initial-config.sh [-h|n|i]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide APIC Namespace value." "CYAN"
	PrintLn "   i     Provide APIC Instance name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "API Connect instance initial configuration." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="apim-demo"
NS_NAME="tools"
OCP_BLOCK_STORAGE=""

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
ValidateJQ
ValidateOC
ValidateNS "$NS_NAME" "NOKEY"
ValidateOpDeployed "datapower"
ValidateOpDeployed "apiconnect"
ValidateInstance "$INST_NAME" "APIConnectCluster" "$NS_NAME"
ValidateAPICcli "$INST_NAME" "$NS_NAME"
PressEnter

##########################
# Define Local Variables #
##########################
MAILSVR_HOST='mailpit-smtp.mailpit.svc.cluster.local'
MAILSVR_PORT=1025
ADMINUSER_EMAIL='admin@cp4i.demo.net'
APIC_REALM='admin/default-idp-1'
APIC_ADMIN_USER='admin'
APIC_ADMIN_ORG='admin'
APIC_MAILSERVER_NAME='dummy-mail-server'
APIC_CMC_USER='integration-admin'
APIC_USER_REGISTRY='integration-keycloak'

PrintLn "Getting APIC access info." "BLUE"
APIC_MGMT_SERVER=$(oc get route "${INST_NAME}-mgmt-platform-api" -n $NS_NAME -o jsonpath="{.spec.host}" --ignore-not-found)
APIC_ADMIN_PWD=$(oc get secret "${INST_NAME}-mgmt-admin-pass" -n $NS_NAME -o jsonpath="{.data.password}" --ignore-not-found | base64 -d)

#################
# LOGIN TO APIC #
#################
PrintLn "Login to APIC with CMC Admin User..." "BLUE"
apic client-creds:clear
apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD

PrintLn "Starting APIC configuration..." "BLUE"
##################################################
# INITIAL APIC CONFIGURATION RIGHT AFTER INSTALL #
# ENABLE API KEY MULTIPLE TIME USAGRE,           #
# UPDATE EMAIL SERVER WITH MAILTRAP INFO AND     #
# ADMIN ACCOUNT EMAIL FIELD.                     #
################################################## 
PrintLn "Enabling API Key multiple time usage..." "BLUE"
apic cloud-settings:update --server $APIC_MGMT_SERVER templates/template-apic-cloud-settings.yaml

PrintLn "Getting Mail Server Info..." "BLUE"
apic mail-servers:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json $APIC_MAILSERVER_NAME

PrintLn "Updating Mail Server Info..." "BLUE"
jq --arg MAILSVR_HOST $MAILSVR_HOST \
	--argjson MAILSVR_PORT $MAILSVR_PORT \
	'.host=$MAILSVR_HOST |
	.port=$MAILSVR_PORT |
	del(.credentials, .created_at, .updated_at)' \
	"${APIC_MAILSERVER_NAME}.json"  > "${APIC_MAILSERVER_NAME}-updated.json"

PrintLn "Updating Mail Server Object..." "BLUE"
apic mail-servers:update --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG $APIC_MAILSERVER_NAME "${APIC_MAILSERVER_NAME}-updated.json"

PrintLn "Getting CMC Admin User Info..." "BLUE"
apic users:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY --format json $APIC_CMC_USER

PrintLn "Updating CMC Admin User eMail Info..." "BLUE"
jq --arg ADMINUSER_EMAIL $ADMINUSER_EMAIL \
	'.email=$ADMINUSER_EMAIL | 
	del(.created_at, .updated_at, .last_login_at)' \
	"${APIC_CMC_USER}.json" > "${APIC_CMC_USER}-updated.json"

PrintLn "Updating CMC Admin User Object..." "BLUE"
apic users:update --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY $APIC_CMC_USER "${APIC_CMC_USER}-updated.json"

PrintLn "Cleaning up temp files..." "BLUE"
rm -f "${APIC_MAILSERVER_NAME}.json"
rm -f "${APIC_MAILSERVER_NAME}-updated.json"
rm -f "${APIC_CMC_USER}.json"
rm -f "${APIC_CMC_USER}-updated.json"

PrintLn "APIC instance $INST_NAME in namespace $NS_NAME has been configured." "GREEN"
