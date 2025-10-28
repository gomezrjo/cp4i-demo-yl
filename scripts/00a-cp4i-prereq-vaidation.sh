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
	PrintLn "Syntax: 02a-cp4i-ns-key-config.sh [-h]" "MAGENTA"
	PrintLn "Options:" "GREEN"
	PrintLn "   h     Print this Help." "CYAN"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

PrintLn "Check CP4I Compute Pre-requisites." "YELLOW"

############################################################
# Set default values for variables                         #
############################################################
MIN_WORKER_NODES='3'
MIN_CPU='80'

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
ValidateJQ
PressEnter

PrintLn "Checking minimum compute requirements..." "BLUE"
num_worker_nodes_jq=$(oc get nodes -o json | jq '.items | map(select(.metadata.labels."node-role.kubernetes.io/worker")) | map(select(.spec.taints == null)) | length')
if [[ "$num_worker_nodes_jq" -ge "MIN_WORKER_NODES" ]]
then
    PrintLn "The OCP Cluster has enough Worker Nodes to proceed. You have $num_worker_nodes_jq" "YELLOW"
else
    PrintLn "The OCP Cluster does not have enough Worker Nodes. You need at least $MIN_WORKER_NODES, but you only have $num_worker_nodes_jq" "RED"
    exit 1
fi
#
total_cpu_jq=$(oc get nodes -o json | jq '.items | map(select(.metadata.labels."node-role.kubernetes.io/worker")) | map(select(.spec.taints == null) | .status.capacity.cpu) | map(tonumber) | add')
if [[ "$total_cpu_jq" -ge "MIN_CPU" ]]
then
    PrintLn "The OCP Cluster has enough Compute (vCPUs) to proceed. You have $total_cpu_jq" "YELLOW"
else
    PrintLn "The OCP Cluster does not have enough Compute (vCPUs). Your need at least $MIN_CPU, but you only have $total_cpu_jq" "RED"
    exit 1
fi
PrintLn "You are ready to start. Have fun!" "GREEN"