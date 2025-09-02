#!/bin/bash
# This script requires the oc command being installed in your environment
# BOLD COLORS
BLACK_BOLD='\033[1;30m'
RED_BOLD='\033[1;31m'
GREEN_BOLD='\033[1;32m'
YELLOW_BOLD='\033[1;33m'
BLUE_BOLD='\033[1;34m'
MAGENTA_BOLD='\033[1;35m'
CYAN_BOLD='\033[1;36m'
WHITE_BOLD='\033[1;37m'
RESET='\033[0m'
# VARIABLES
MIN_WORKER_NODES='3'
MIN_CPU='80'
if [ ! command -v oc &> /dev/null ]; then echo -e "${RED_BOLD}oc could not be found.${RESET}"; exit 1; fi;
if [ ! command -v awk &> /dev/null ]; then echo -e "${RED_BOLD}awk could not be found.${RESET}"; exit 1; fi;
echo -e "${BLUE_BOLD}Checking minimum compute requirements...${RESET}"
num_worker_nodes_jq=$(oc get nodes -o json | jq '.items | map(select(.metadata.labels."node-role.kubernetes.io/worker")) | map(select(.spec.taints == null)) | length')
if [[ "$num_worker_nodes_jq" -ge "MIN_WORKER_NODES" ]]
then
    echo -e "${YELLOW_BOLD}The OCP Cluster has enough Worker Nodes to proceed. You have $num_worker_nodes_jq${RESET}"
else
    echo -e "${RED_BOLD}The OCP Cluster does not have enough Worker Nodes. You need at least $MIN_WORKER_NODES, but you only have $num_worker_nodes_jq${RESET}"
    exit 1
fi
#
total_cpu_jq=$(oc get nodes -o json | jq '.items | map(select(.metadata.labels."node-role.kubernetes.io/worker")) | map(select(.spec.taints == null) | .status.capacity.cpu) | map(tonumber) | add')
if [[ "$total_cpu_jq" -ge "MIN_CPU" ]]
then
    echo -e "${YELLOW_BOLD}The OCP Cluster has enough Compute (vCPUs) to proceed. You have $total_cpu_jq${RESET}"
else
    echo -e "${RED_BOLD}The OCP Cluster does not have enough Compute (vCPUs). Your need at least $MIN_CPU, but you only have $total_cpu_jq${RESET}"
    exit 1
fi
if [ -z "$CP4I_VER" ]; then echo -e "${RED_BOLD}CP4I_VER not set, it must be provided on the command line.${RESET}"; exit 1; fi;
echo -e "${YELLOW_BOLD}CP4I_VER has been set to $CP4I_VER${RESET}"
if [ "$CP4I_VER" != "SC2" ] && [ "$CP4I_VER" != "CD" ]; then echo -e "${RED_BOLD}The CP4I version is invalid. Valid options are SC2 (aka LTS) for v16.1.0 and CD for v16.1.2${RESET}"; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo -e "${RED_BOLD}OCP_TYPE not set, it must be provided on the command line.${RESET}"; exit 1; fi;
echo -e "${YELLOW_BOLD}OCP_TYPE has been set to $OCP_TYPE${RESET}"
echo -e "${BLUE_BOLD}Checking storage classes...${RESET}"
if [[ $(oc get sc --no-headers -o=custom-columns='NAME:.metadata.name' | wc -l) -eq 0 ]]
then
    echo -e "${RED_BOLD}Storage Classes are NOT available in your cluster. Check the OCP cluster has been fully provisioned."
    exit 1
else
    case "$OCP_TYPE" in
        "ODF")
            SCS=(ocs-storagecluster-ceph-rbd ocs-storagecluster-cephfs);;
        "TZEXT")
            SCS=(ocs-external-storagecluster-ceph-rbd ocs-external-storagecluster-cephfs);;
    *)
        echo -e "${RED_BOLD}The Storage Class Type is invalid. Valid options are ODF or TZEXT.${RESET}"
        exit 1;;
    esac
    for SC_NAME in "${SCS[@]}"
    do
        SC_CHECK=$(oc get sc --no-headers -o=custom-columns='NAME:.metadata.name' | awk -v scname=$SC_NAME '$1 == scname {print $1}')
        if [ -z $SC_CHECK ];then echo -e "${RED_BOLD}OCP_TYPE does not match the storage classes available in your cluster.${RESET}"; exit 1;fi
    done
fi
echo -e "${YELLOW_BOLD}The Storage Classes in your OCP cluster match the OCP_TYPE specified, you can proceed.${RESET}"
if [ -z "$CP4I_TRACING" ]; then echo -e "${YELLOW_BOLD}CP4I Tracing is NOT enabled.${RESET}"; else echo -e "${YELLOW_BOLD}CP4I Tracing is enabled.${RESET}"; fi;
echo -e "${GREEN_BOLD}You are ready to start. Have fun!${RESET}"