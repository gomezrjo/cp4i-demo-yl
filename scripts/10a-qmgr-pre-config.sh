#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
QMGR_NAME='qmgr-demo'
QMGR_NAMESPACE='tools'
##################################
# QUEUE MANAGER PRECONFIGURATION #
##################################
echo "Preconfiguring Queue Manager..."
oc apply -f resources/00-gitops-clusterissuer.yaml
echo "Creating Certificate Template..."
OCP_CLUSTER_DOMAIN=$(oc get IngressController default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
( echo "cat <<EOF" ; cat templates/template-mq-certificate.yaml ;) | \
    QMGR_NAME=${QMGR_NAME} \
    QMGR_NAMESPACE=${QMGR_NAMESPACE} \
    OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
    sh > mq-certificate.yaml
echo "Creating Certificate..."
oc apply -f mq-certificate.yaml
oc -n ${QMGR_NAMESPACE} label secret ${QMGR_NAME}-tls-secret assembly.integration.ibm.com/tools.jgr-demo=true
#oc create secret tls mq-demo-tls-secret -n cp4i --key="artifacts/qmgr-server-tls.key" --cert="artifacts/qmgr-server-tls.crt"
echo "Creating Route..."
oc create -f resources/03b-qmgr-tls-route.yaml
echo "Cleaning up temp files..."
rm -f mq-certificate.yaml
echo "Queue Manager preconfiguration completed."