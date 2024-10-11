#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
QMGR_NAMESPACE='cp4i'
##################################
# QUEUE MANAGER PRECONFIGURATION #
##################################
echo "Preconfiguring Queue Manager for Uniform Cluster..."
OCP_CLUSTER_DOMAIN=$(oc get IngressController default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
echo "Creating Certificate Template for QM1..."
QMGR_NAME='uniform-cluster-qm1'
( echo "cat <<EOF" ; cat templates/template-mq-certificate.yaml ;) | \
    QMGR_NAME=${QMGR_NAME} \
    QMGR_NAMESPACE=${QMGR_NAMESPACE} \
    OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
    sh > mq-certificate.yaml
echo "Creating Certificate for QM1..."
oc apply -f mq-certificate.yaml
rm -f mq-certificate.yaml
echo "Creating Certificate Template for QM2..."
QMGR_NAME='uniform-cluster-qm2'
( echo "cat <<EOF" ; cat templates/template-mq-certificate.yaml ;) | \
    QMGR_NAME=${QMGR_NAME} \
    QMGR_NAMESPACE=${QMGR_NAMESPACE} \
    OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
    sh > mq-certificate.yaml
echo "Creating Certificate for QM2..."
oc apply -f mq-certificate.yaml
echo "Cleaning up temp files..."
rm -f mq-certificate.yaml
echo "Queue Managers for Uniform Cluster preconfiguration completed."