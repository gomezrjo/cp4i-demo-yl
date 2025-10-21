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
	PrintLn "Syntax: 00d-cp4i-operators-install.sh [-h|v|o|r]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   v     Provide CP4I Version (CD | SC2)." "CYAN"
	PrintLn "   o     Provide CP4I Operator short name." "CYAN"
	PrintLn "   r     Provide CP4I Operator release." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Deploy CP4I Operators." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
if [ -z "$CP4I_VER" ]; then
    CP4I_VERSION="CD"
else
    CP4I_VERSION=$CP4I_VER
fi
OP_NAME=""
OP_REL=""

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":v:o:r:h"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # display Help
			Help
			exit;;
		v) # Update version value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			CP4I_VERSION=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]');;
		o) # Get operator name
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			OP_NAME=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]');;
		r) # Get operator release
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			OP_REL="-$OPTARG";;
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

# Check for mandatory arguments
if [ -z "$OP_NAME" ]; then
  PrintLn "ERROR: -o (operator name) is a mandatory argument." "RED"
  Help
  exit 1
fi

PrintLn "Checking pre-requisites..." "BLUE"
ValidateVer "$CP4I_VERSION"
ValidateOC
ValidateOpName "$OP_NAME"
ValidateCatRel "$CP4I_VERSION" "${CAT_MANIFESTS[$OP_IND]}" "$OP_REL"
PressEnter

if [ $OP_NAME == "common-services" ]; then
    PrintLn "Creating namespace for common services..." "BLUE"
    if [[ -z "$(oc projects -q | awk '$1 == "ibm-common-services" {print $1}')" ]]; then
        oc create namespace ibm-common-services
    else
        PrintLn "Namespace ibm-common-services already exists." "GREEN"
    fi
fi

MANIFEST_NAME="${CAT_MANIFESTS[$OP_IND]}${OP_REL}.yaml"
CATALOG_NAME=${CATALOGS[$OP_IND]}
PrintLn "Deploying Catalog Source..." "BLUE"
oc apply -f catalog-sources/$CP4I_VERSION/$MANIFEST_NAME
PrintLn "Waiting for Catalog Source to be ready..." "BLUE"
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/$CATALOG_NAME -n openshift-marketplace 2>/dev/null; do 
	sleep 5
done
MANIFEST_NAME=${SUB_MANIFESTS[$OP_IND]}
PrintLn "Deploying Operator..." "BLUE"
oc apply -f subscriptions/$CP4I_VERSION/$MANIFEST_NAME
PrintLn "Done! Check progress..." "GREEN"
