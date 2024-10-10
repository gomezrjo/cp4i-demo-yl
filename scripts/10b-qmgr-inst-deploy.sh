#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
echo "OCP_TYPE is set to" $OCP_TYPE
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is enabled"; fi;
read -p "Press <Enter> to execute script..."
if [ -z "$CP4I_TRACING" ]
then
    echo "Deploying Queue Manager instance without tracing..."
    oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/09-qmgr-ace-single-instance.yaml
else
    echo "Deploying Queue Manager instance with tracing enabled..."
    oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/tracing/09-qmgr-ace-single-tracing-instance.yaml
fi
echo "Done!"