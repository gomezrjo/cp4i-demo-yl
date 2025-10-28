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
	PrintLn "Syntax: 02a-cp4i-ns-key-config.sh [-h|n|k]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
	PrintLn "   n     Provide CP4I Namespace(s) list." "CYAN"
    PrintLn "   k     Provide Entitlement Key value." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Check CP4I Operators deployment." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
if [ ! -z "$ENT_KEY" ]; then
    E_KEY="$ENT_KEY"
fi
USER_NAME="cp"
NS_LIST=""

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":n:k:h"
# Get the options
while getopts ${OPTSTRING} option; do
	case $option in
		h) # display Help
			Help
			exit;;
		n) # Update namespace value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			NS_LIST=$OPTARG;;
		k) # Update ent key value
			if [[ "$OPTARG" == -* ]]; then
				PrintLn "ERROR: Option -$option requires an argument, but received another option: $OPTARG" "RED"
				Help
				exit 1
			fi
			E_KEY=$OPTARG;;
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

if [ -z "$E_KEY" ]; then
    PrintLn "ERROR: ENT_KEY is not set. Check Env Variable ENT_KEY or Option -k and try again." "RED"
    exit 1
fi
PrintLn "INFO: ENT_KEY is set to $E_KEY" "YELLOW"
PressEnter

# CP4I_NAMESPACES=(cp4i cp4i-ace cp4i-apic cp4i-aspera cp4i-assetrepo cp4i-dp cp4i-eventstreams cp4i-mq cp4i-tracing)
# CP4I_NAMESPACES=(student1 student2 student3 student4 student5 student6 student7 student8 student9 student10 student11 student12 student13 student14 student15 student16 student17 student18 student19 student20) 
#CP4I_NAMESPACES=(cp4i-apic)
PrintLn "Setting array with list of namespaces $NS_LIST..." "BLUE"
if [ -z "$NS_LIST" ]; then
	CP4I_NAMESPACES=(tools cp4i cp4i-mq cp4i-dp cp4i-apic cp4i-es cp4i-ea mq-argocd stepzen london rome)
else
	old_IFS="$IFS"
	IFS=','
	read -ra CP4I_NAMESPACES <<< "$NS_LIST"
	IFS="$old_IFS"
fi

for NS in "${CP4I_NAMESPACES[@]}"
do
    PrintLn "Creating a new namespace called $NS..." "BLUE"
    if [[ -z "$(oc projects -q | awk -v ns=$NS '$1 == ns {print $1}')" ]]; then
        oc new-project $NS &>/dev/null
		echo "project/$NS created"
    else
        PrintLn "Namespace $NS already exists." "GREEN"
    fi

    PrintLn "Creating ibm-entitlement-key in namespace $NS..." "BLUE"
    if [[ -z "$(oc get secret ibm-entitlement-key -n $NS --no-headers --ignore-not-found=true)" ]]; then
        oc create secret docker-registry ibm-entitlement-key \
            --docker-username=$USER_NAME \
            --docker-password=$E_KEY \
            --docker-server=cp.icr.io \
            --namespace=$NS
    else
        PrintLn "ibm-entitlement-key already exists in namespace $NS" "GREEN"
    fi
done