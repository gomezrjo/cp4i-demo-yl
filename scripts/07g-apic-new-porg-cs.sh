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
	PrintLn "Syntax: 07g-apic-new-porg-cs.sh [-h|n|i|p]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide APIC Namespace value." "CYAN"
	PrintLn "   i     Provide APIC Instance name." "CYAN"
    PrintLn "   p     Provide Provider Organization name." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "API Connect Provider Organization configuration." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
INST_NAME="apim-demo"
NS_NAME="tools"
OCP_BLOCK_STORAGE=""
PORG_NAME='cp4i-demo-org'
APIC_DEP_VER=""

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
		p) # Update instance value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			PORG_NAME=$OPTARG;;
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
ValidateNS "$NS_NAME" "NOKEY"
ValidateOpDeployed "datapower"
ValidateOpDeployed "apiconnect"
ValidateInstance "$INST_NAME" "APIConnectCluster" "$NS_NAME"
ValidateAPICcli "$INST_NAME" "$NS_NAME"
PressEnter

##########################
# Define Local Variables #
##########################
APIC_REALM='admin/default-idp-1'
APIC_ADMIN_USER='admin'
APIC_ADMIN_ORG='admin'
APIC_CMC_USER='integration-admin'
APIC_USER_REGISTRY='integration-keycloak'
if [ "$PORG_NAME" == "cp4i-demo-org" ]; then
	PORG_TITLE='CP4I Demo Provider Org'
else
	PORG_TITLE="$PORG_NAME"
fi

PrintLn "Getting APIC access info." "BLUE"
APIC_MGMT_SERVER=$(oc get route "${INST_NAME}-mgmt-platform-api" -n $NS_NAME -o jsonpath="{.spec.host}" --ignore-not-found)
APIC_ADMIN_PWD=$(oc get secret "${INST_NAME}-mgmt-admin-pass" -n $NS_NAME -o jsonpath="{.data.password}" --ignore-not-found | base64 -d)

#################
# LOGIN TO APIC #
#################
PrintLn "Login to APIC with CMC Admin User..." "BLUE"
apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD


###########################
# CREATE NEW PROVIDER ORG #
###########################
PrintLn "Validating if Provider Organization $PORG_NAME exists..." "BLUE"
PORG=$(apic orgs:list --server $APIC_MGMT_SERVER | awk -v porgname=$PORG_NAME '$1 == porgname { ++count } END { print count }')
if [ -z $PORG ] 
then
	PrintLn "Starting APIC configuration..." "BLUE"
   	PrintLn "Getting Values to Create Provider Organization $PORG_NAME..." "BLUE"
   	if [ "$APIC_DEP_VER" = "10.0.10.0" ]; then 
    	USER_URL=$(apic users:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY | awk -v user=$APIC_CMC_USER '$1 == user {print $3}')
   	else
    	USER_URL=$(apic users:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY | awk -v user=$APIC_CMC_USER '$1 == user {print $4}')
   	fi
   	PrintLn "Preparing POrg File for user $APIC_CMC_USER..." "BLUE"
	( echo "cat <<EOF" ; cat templates/template-apic-provider-org.json ;) | \
		PORG_NAME=${PORG_NAME} \
		PORG_TITLE=${PORG_TITLE} \
		USER_URL=${USER_URL} \
		sh > provider-org.json
	PrintLn "Creating POrg for user $APIC_CMC_USER..." "BLUE"
	apic orgs:create --server $APIC_MGMT_SERVER provider-org.json
	PrintLn "Cleaning up temp files..." "BLUE"
	rm -f provider-org.json
	PrintLn "Provider Organization $PORG_NAME has been created." "GREEN"
else 
   	PrintLn "Provider Organization $PORG_NAME already exists. No action taken." "GREEN"
fi