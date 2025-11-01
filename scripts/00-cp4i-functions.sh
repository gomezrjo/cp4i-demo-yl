############################################################
############################################################
# Global Variables                                         #
############################################################
############################################################
OPERATORS=('common-services'
            'cp4i' 
            'asset-repo' 
            'datapower' 
            'apiconnect'
            'eventstreams'
            'eem'
            'mq'
            'appconnect'
            'ea-flink'
            'ep'
            'cert-manager')
DEPLOYMENTS=('ibm-common-service-operator'
            'ibm-integration-platform-navigator-operator' 
            'ibm-integration-asset-repository-operator'
            'datapower-operator' 
            'ibm-apiconnect'
            'eventstreams-cluster-operator'
            'ibm-eem-operator'
            'ibm-mq-operator'
            'ibm-appconnect-operator'
            'flink-kubernetes-operator'
            'ibm-ep-operator'
            'cert-manager-operator-controller-manager')
CAT_MANIFESTS=('02-common-services-catalog-source'
                '03-platform-navigator-catalog-source'
                '04-asset-repo-catalog-source'
                '05-datapower-catalog-source'
                '07-api-connect-catalog-source'
                '08-event-streams-catalog-source'
                '13-eem-catalog-source'
                '09-mq-catalog-source'
                '10-app-connect-catalog-source'
                '14-ea-flink-catalog-source'
                '15-event-processing-catalog-source')
CATALOGS=('opencloud-operators'
            'ibm-integration-platform-navigator-catalog'
            'ibm-integration-asset-repository-catalog'
            'ibm-datapower-operator-catalog'
            'ibm-apiconnect-catalog'
            'ibm-eventstreams'
            'ibm-eventendpointmanagement-catalog'
            'ibmmq-operator-catalogsource'
            'appconnect-operator-catalogsource'
            'ibm-eventautomation-flink-catalog'
            'ibm-eventprocessing-catalog')
SUB_MANIFESTS=('00-common-services-subscription.yaml'
                '01-platform-navigator-subscription.yaml'
                '02-asset-repo-subscription.yaml'
                '03-datapower-subscription.yaml'
                '04-api-connect-subscription.yaml'
                '05-event-streams-subscription.yaml'
                '09-eem-subscription.yaml'
                '06-mq-subscription.yaml'
                '07-app-connect-subscription.yaml'
                '10-ea-flink-subscription.yaml'
                '11-event-processing-subscription.yaml')
OP_IND=""

############################################################
############################################################
# Routines                                                 #
############################################################
############################################################
SetTextColor()
{
    local COLOR=$1

    # BOLD COLORS    
    local COLORS=(BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE RESET)
    local CODES=('\033[1;30m' '\033[1;31m' '\033[1;32m' '\033[1;33m' '\033[1;34m' '\033[1;35m' '\033[1;36m' '\033[1;37m' '\033[0m')

    # Initialize a variable to store the index
    local found_index=-1

    # Iterate through the array with its indices
    for i in "${!COLORS[@]}"; do
        if [[ "${COLORS[$i]}" == "$COLOR" ]]; then
            found_index=$i
            break # Exit the loop once the element is found
        fi
    done

    # Check if the element was not found and set default color
    if [[ $found_index -eq -1 ]]; then found_index=8; fi;

    echo -n -e "${CODES[$found_index]}"
}

PrintLn()
{
    if [ $# -lt 1 ]; then
        echo -e "\033[1;31mERROR: PrintLn routine missing argument. Check if you have modified the scripts.\033[0m"
        exit 1
    fi
    
    local TEXT=$1
    local COLOR=$2
    
    # BOLD COLORS    
    local COLORS=(BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE)
    local CODES=('\033[1;30m' '\033[1;31m' '\033[1;32m' '\033[1;33m' '\033[1;34m' '\033[1;35m' '\033[1;36m' '\033[1;37m')
    local RESET='\033[0m'

    # Initialize a variable to store the index
    local found_index=-1

    # Iterate through the array with its indices
    for i in "${!COLORS[@]}"; do
        if [[ "${COLORS[$i]}" == "$COLOR" ]]; then
            found_index=$i
            break # Exit the loop once the element is found
        fi
    done

    # Check if the element was not found and set default color
    if [[ $found_index -eq -1 ]]; then found_index=7; fi;

    echo -e "${CODES[$found_index]}$TEXT${RESET}"
}

PressEnter()
{
    # BOLD COLORS
    local MAGENTA='\033[1;35m'
    local RESET='\033[0m'
    echo -n -e "${MAGENTA}"
    read -p "Press <Enter> to continue..."
    echo -n -e "${RESET}"
}

ValidateAWK()
{
    # Check if oc cli is available in workstation
    if ! command -v awk &> /dev/null; then 
        PrintLn "ERROR: awk could not be found in workstation." "RED"
        exit 1
    fi
}

ValidateJQ()
{
    # Check if jq cli is available in workstation
    if ! command -v jq &> /dev/null; then 
        PrintLn "ERROR: jq could not be found in workstation." "RED"
        exit 1
    fi
}

ValidateYQ()
{
    # Check if jq cli is available in workstation
    if ! command -v yq &> /dev/null; then 
        PrintLn "ERROR: jq could not be found in workstation." "RED"
        exit 1
    fi
}

ValidateDepMode1()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateDepMode1 routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR:ValidateDepMode1 routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local DM=$1

    PrintLn "INFO: DEP_MODE is set to $DM" "YELLOW"
    if [ "$DM" != "STD" ] && [ "$DM" != "POT" ]; then 
        PrintLn "ERROR: DEP_MODE is not valid. Check Option -d. Valid values are STD | POT." "RED"
        exit 1
    fi
}

ValidateDepMode2()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateDepMode2 routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR:ValidateDepMode2 routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local DM=$1

    PrintLn "INFO: DEP_MODE is set to $DM" "YELLOW"
    if [ "$DM" != "STD" ] && [ "$DM" != "B2B" ]; then 
        PrintLn "ERROR: DEP_MODE is not valid. Check Option -d. Valid values are STD | POT." "RED"
        exit 1
    fi
}

ValidateVer()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateVer routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: ValidateNS routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local CPV=$1

    PrintLn "INFO: CP4I_VER is set to $CPV" "YELLOW"
    if [ "$CPV" != "SC2" ] && [ "$CPV" != "CD" ]; then 
        PrintLn "ERROR: CP4I_VER is not valid. Check Env Variable CP4I_VER or Option -v. Valid values are CD | SC2." "RED"
        exit 1
    fi
}

ValidateAuth()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateAuth routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: ValidateAuth routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local AUT=$1

    PrintLn "INFO: AUTH_TYPE is set to $AUT" "YELLOW"
    if [ "$AUT" != "LOCAL" ] && [ "$AUT" != "OIDC" ]; then 
        PrintLn "ERROR: AUTH_TYPE is not valid. Check Option -a. Valid values are LOCAL | OIDC." "RED"
        exit 1
    fi
}

ValidateToken()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateToken routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: ValidateToken routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local TKN=$1
    local DELIMITER="-"
    IFS="$DELIMITER" read -ra my_array <<< "$TKN"
    local num_elements=${#my_array[@]}
    
    PrintLn "INFO: APIKEY/TOKEN is set to $AUT" "YELLOW"
    if [ $num_elements -ne 5 ]; then
        PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format." "RED"
        exit 1
    else
        local allowed_chars_regex="^[a-z0-9]+$"
        for i in $(seq 0 4); do
            string_length=${#my_array[$i]}
            case $i in
            0)
                if [ $string_length -ne 8 ];then
                    PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format." "RED"
                    exit 1
                fi
                ;;
            4)
                if [ $string_length -ne 12 ];then
                    PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format." "RED"
                    exit 1
                fi
                ;;
            *)
                if [ $string_length -ne 4 ];then
                    echo PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format." "RED"
                    exit 1
                fi
                ;;
            esac
            my_item="${my_array[$i]}"
            if [[ ! "$my_item" =~ $allowed_chars_regex  ]]; then
                PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format." "RED"
                exit 1
            fi
        done
    fi
}

ValidateOC()
{
    # Check if oc cli is available in workstation
    if ! command -v oc &> /dev/null; then 
        PrintLn "ERROR: oc could not be found in workstation." "RED"
        exit 1
    fi

    local CLUSTER_NAME=""

    oc status &> /dev/null
    if [ $? -ne 0 ]; then
        PrintLn "ERROR: You are not logged into the OCP cluster. Check and try again." "RED"
        exit 1
    fi

    CLUSTER_NAME=$(oc config view --minify --output 'jsonpath={.clusters[].name}' | cut -d':' -f1)
    PrintLn "INFO: You are logged into OCP cluster $CLUSTER_NAME" "YELLOW"
}

ValidateNS()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateNS routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: ValidateNS routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local NS=$1
    local EK="YES"
    local ETQ="Base"

    if [ ! -z "$2" ]; then
        if [ "$2" != "NOKEY" ]; then
            PrintLn "ERROR: ValidateNS routine invalid argument. Check if you have modified the scripts." "RED"
            exit 1
        else
            EK="NO"
        fi
    fi

    if [ ! -z "$3" ]; then
        if [ "$3" != "EXTRA" ]; then
            PrintLn "ERROR: ValidateNS routine invalid argument. Check if you have modified the scripts." "RED"
            exit 1
        else
            ETQ="Extra"
        fi
    fi

    PrintLn "INFO: $ETQ Namespace is set to $NS" "YELLOW"
    if [[ -z "$(oc get project --no-headers | awk -v nsname="${NS}" '$1 == nsname {print $1}')" ]]; then
        PrintLn "ERROR: Namespace $NS doesn't exist. Check and try again." "RED"
        exit 1
    fi

    if [ "$EK" == "YES" ]; then
        if [[ -z "$(oc get secret ibm-entitlement-key --ignore-not-found --no-headers -n $NS)" ]]; then
            PrintLn "ERROR: Namespace $NS doesn't have an entitlement key. Check and try again." "RED"
            exit 1
        fi
    fi
    
}

ValidateSC()
{
    if [ $# -lt 2 ]; then
        PrintLn "ERROR: ValidateSC routine missing argument(s). Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: ValidateSC routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local SCT=$1
    local SCN=$2

    if [ -z $SCN ]; then
        PrintLn "INFO: OCP_TYPE is set to $SCT" "YELLOW"
    else
        PrintLn "INFO: Storage Class is set to $SCN" "YELLOW"
    fi

    if [ -z $SCN ]; then
        PrintLn "Setting Storage Class..." "BLUE"
        case "$SCT" in
            "ODF")
                OCP_BLOCK_STORAGE='ocs-storagecluster-ceph-rbd'
                OCP_FILE_STORAGE='ocs-storagecluster-cephfs'
                ;;
            "ROKS")
                #OCP_BLOCK_STORAGE='ibmc-block-gold'
                OCP_BLOCK_STORAGE='ibmc-block-gold-wffc'
                OCP_FILE_STORAGE='ibmc-file-gold-gid'
                ;;
            "TZEXT")
                OCP_BLOCK_STORAGE='ocs-external-storagecluster-ceph-rbd'
                OCP_FILE_STORAGE='ocs-external-storagecluster-cephfs'
                ;;    
        *)
            PrintLn "ERROR: Incorrect SC Type. Check Env Variable OCP_TYPE or Option -t. Valid values are TZEXT | ODF | ROKS." "RED"
            exit 1
            ;;
        esac
        PrintLn "Storage Class is set to $OCP_BLOCK_STORAGE" "CYAN"
    else
        OCP_BLOCK_STORAGE=$SCN
    fi
    if [ -z "$(oc get sc ${OCP_BLOCK_STORAGE} --no-headers --ignore-not-found)" ]; then
        PrintLn "ERROR: Storage Class is NOT available in OCP Cluster. Check your cluster and try again." "RED"
        exit 1
    fi
}

ValidateAPICcli()
{
    # Check if apic cli is available in workstation
    if ! command -v apic &> /dev/null; then 
        PrintLn "ERROR: apic cli could not be found in workstation." "RED"
        exit 1
    fi

    if [ -z "$1" ] || [ -z "$2" ]; then
        PrintLn "ERROR: ValidateAPICcli routine empty argument(s). Check if you have modified the scripts." "RED"
        exit 1
    fi

    local INST_NAME=$1
    local NS=$2
    local CMD_RESP=""
    local TEMP_TEXT=""
    local APIC_CLI_VER=""

    CMD_RESP=$(apic version | head -2 | tail -1)
    TEMP_TEXT="${CMD_RESP#* }"
    CMD_RESP=$(echo "$TEMP_TEXT" | sed 's/[[:space:]]*$//')
    APIC_CLI_VER="${CMD_RESP:1}"
    PrintLn "APIC CLI Version: $APIC_CLI_VER" "CYAN"

    CMD_RESP=$(oc get apiconnectcluster $INST_NAME -n $NS -o jsonpath='{.status.versions.reconciled}')
    APIC_DEP_VER="${CMD_RESP%-*}"
    PrintLn "APIC Cluster Version: $APIC_DEP_VER" "CYAN"

    if [ "$APIC_CLI_VER" != "$APIC_DEP_VER" ]; then
        PrintLn "ERROR: APIC CLI does not match APIC Cluster version. Update APIC CLI and try again." "RED"
        exit 1
    fi
}

ValidateAPIKey()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateAPIKey routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: APIC_API_KEY is not set. It must be provided as Env Variable or via parameter -k. Check and try again." "RED"
        exit 1
    fi

    local KEY=$1
    local DELIMITER="-"
    IFS="$DELIMITER" read -ra my_array <<< "$KEY"
    local num_elements=${#my_array[@]}
    
    PrintLn "INFO: APIC_API_KEY is set to $KEY" "YELLOW"
    if [ $num_elements -ne 5 ]; then
        PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format. Format should be XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" "RED"
        exit 1
    else
        local allowed_chars_regex="^[a-z0-9]+$"
        for i in $(seq 0 4); do
            string_length=${#my_array[$i]}
            case $i in
            0)
                if [ $string_length -ne 8 ];then
                    PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format. Format should be XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" "RED"
                    exit 1
                fi
                ;;
            4)
                if [ $string_length -ne 12 ];then
                    PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format. Format should be XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" "RED"
                    exit 1
                fi
                ;;
            *)
                if [ $string_length -ne 4 ];then
                    echo PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format. Format should be XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" "RED"
                    exit 1
                fi
                ;;
            esac
            my_item="${my_array[$i]}"
            if [[ ! "$my_item" =~ $allowed_chars_regex  ]]; then
                PrintLn "ERROR: The APIKEY/TOKEN does not have the expected format. Format should be XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" "RED"
                exit 1
            fi
        done
    fi
}

ValidateCatRel()
{
    if [ $# -lt 3 ]; then
        PrintLn "ERROR: ValidateCatRel routine missing arguments. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ] || [ -z "$2" ]; then
        PrintLn "ERROR: ValidateCatRel routine empty argument(s). Check if you have modified the scripts." "RED"
        exit 1
    fi

    local CV=$1
    local CM=$2
    local CR=$3
    local CRD="${CR#?}"
    local FN="catalog-sources/$CV/$CM$CR.yaml"

    if [ -z "$CR" ]; then
        PrintLn "INFO: Operator's latest release will be used" "YELLOW"
    else
        PrintLn "INFO: Operator's release $CRD will be used" "YELLOW"
    fi

    if [ ! -f "$FN" ]; then
        PrintLn "ERROR: Invalid Catalog Release $CRD. Check option -r and try again." "RED"
        exit 1
    fi
}

GetOperatorIndex()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: GetOperatorIndex routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: GetOperatorIndex routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local OP_NAME=$1

    # Initialize a variable to store the index
    local found_index=-1

    # Iterate through the array with its indices
    for i in "${!OPERATORS[@]}"; do
        if [[ "${OPERATORS[$i]}" == "$OP_NAME" ]]; then
            found_index=$i
            break # Exit the loop once the element is found
        fi
    done

    # Check if the element was not found and set default color
    OP_IND=$found_index
}

ValidateOpName()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateOpName routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: ValidateOpName routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local OP_NAME=$1

    PrintLn "INFO: Operator Short Name is set to $OP_NAME" "YELLOW"
    GetOperatorIndex "$OP_NAME"    
    # Check if the element was found
    if [[ $OP_IND -eq -1 ]]; then 
        PrintLn "ERROR: Invalid Short Operator Name $OP_NAME. Check if you have modified the scripts." "RED"
        exit 1
    fi
}

ValidateOpDeployed()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateOperator routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: ValidateEnv routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local OP_NAME=$1

    GetOperatorIndex "$OP_NAME"
    # Check if the element was found
    if [[ $OP_IND -eq -1 ]]; then 
        PrintLn "ERROR: Invalid Short Operator Name $OP_NAME. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [[ -z "$(oc get deployment ${DEPLOYMENTS[$OP_IND]} -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')" ]]; then 
        PrintLn "ERROR: $OP_NAME Operator is not installed in OCP Cluster. Check and try again." "RED"
        exit 1
    fi
}

ValidateInstType()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: ValidateInstType routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: ValidateInstType routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local CT=$1

    PrintLn "INFO: Resource Type is set to $CT" "YELLOW"
    if [[ -z "$(oc api-resources --no-headers | awk -v apiname="${CT}" 'tolower($NF) == tolower(apiname) {print $NF}')" ]]; then
        PrintLn "ERROR: The OCP Cluster does NOT have a Resource Type $CT. Check if you didn't skip a step in the ReadMe." "RED"
        exit 1
    fi
}

ValidateInstance()
{
    if [ $# -lt 3 ]; then
        PrintLn "ERROR: ValidateInstance routine missing arguments. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        PrintLn "ERROR: ValidateEnv routine empty argument(s). Check if you have modified the scripts." "RED"
        exit 1
    fi

    local INST_NAME=$1
    local INST_TYPE=$(echo "$2" | tr '[:upper:]' '[:lower:]')
    local NS=$3
    local INST_STATUS=""

    if [[ -z "$(oc api-resources --no-headers | awk -v apiname="${INST_TYPE}" 'tolower($NF) == tolower(apiname) {print $NF}')" ]]; then
        PrintLn "ERROR: The OCP Cluster does NOT have a Resource Type $INST_TYPE. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [[ -z "$(oc get ${INST_TYPE} ${INST_NAME} -n ${NS} --ignore-not-found --no-headers)" ]]; then
        PrintLn "ERROR: Instance $INST_NAME is not installed in namespace $NS. Check and try again." "RED"
        exit 1
    fi

    if [ "$INST_TYPE" == "platformnavigator" ]; then
        INST_STATUS=$(oc get ${INST_TYPE} ${INST_NAME} -n ${NS} -o jsonpath='{.status.conditions[0].type}')
    else
        INST_STATUS=$(oc get ${INST_TYPE} ${INST_NAME} -n ${NS} -o jsonpath='{.status.phase}')
    fi

    if [ "$INST_STATUS" != "Ready" ] && [ "$INST_STATUS" != "Running" ]; then
        PrintLn "ERROR: Instance $INST_NAME in namespace $NS is not ready. Check and try again." "RED"
        exit 1
    fi
}

SaveManifest()
{
    if [ $# -lt 1 ]; then
        PrintLn "ERROR: SaveManifest routine missing argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    if [ -z "$1" ]; then
        PrintLn "ERROR: SaveManifest routine empty argument. Check if you have modified the scripts." "RED"
        exit 1
    fi

    local MANIFEST_NAME=$1
    local CLUSTER_NAME=""

    CLUSTER_NAME=$(oc config view --minify --output 'jsonpath={.clusters[].name}' | cut -d':' -f1)
    if [ ! -d "artifacts/${CLUSTER_NAME}" ]; then
        mkdir "artifacts/${CLUSTER_NAME}"
    fi
    CURR_DATE=$(date +%Y%m%d)
    cp "$MANIFEST_NAME.yaml" "artifacts/${CLUSTER_NAME}/$MANIFEST_NAME-$CURR_DATE.yaml"
}