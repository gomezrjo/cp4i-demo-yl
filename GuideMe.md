# IBM Cloud Pak for Integration deployment guide

To use this guide you will need to clone this repo to your workstation.

Additionally you will need to have installed the following tools in your workstation:

* [oc cli](https://docs.openshift.com/container-platform/4.8/cli_reference/openshift_cli/getting-started-cli.html)
* [jq](https://stedolan.github.io/jq/)
* [yq](https://github.com/mikefarah/yq)

This guide assumes you already have an OCP cluster with the right version and capacity up and running in [TechZone](https://techzone.ibm.com/home), and that you are already logged into your OCP cluster. For best results I recommend you use OCP v4.18.x with 5 worker nodes 32 vCPUs X 128 GB memory each.

Check the list of pre-requisites before using this guide using the following command:
   ```
   scripts/00a-cp4i-tools-prereq-vaidation.sh
   ```

Once you confirm you have the required tools in your workstation you are ready to use the following guide.

<details>
<summary>
A) Set environment variables:
</summary>

1. By default the scripts assume you will use the latest CD (v16.1.2) release. If you want to use the latest LTS (aka SC2 - v16.1.0) use the following command to set the corresponding CP4I version, otherwise go to the next step.
    ```
    export CP4I_VER=SC2
    ```
2. By default the storage classes used by the scripts are set to TZEXT since this corresponds to the storage classes used by the OCP-V clusters, which are the recommended type of cluster by the TZ Team, but if you are using the traditional UPI deployment then set the OCP type accordingly using the following command:
    ```
    export OCP_TYPE=ODF
    ```
</details>
&nbsp; 

<details>
<summary>
B) Prepare your cluster:
</summary>

1. Validate the OCP cluster meets the minimum requirements using the following script:
   ```
   scripts/00a-cp4i-prereq-vaidation.sh
   ```
2. Configure image registry for your cluster. If you have provisioned your OCP cluster in Tech Zone using OCP-V you can use the following script to enable the image registry:
   ```
   scripts/99-setup-image-registry.sh
   ```
</details>
&nbsp;

<details>
<summary>
C) Install Common Services and its pre-requisites:
</summary>   

1. Install Cert Manager Operator:
   ```
   scripts/00f-cert-manager-operator-install.sh
   ```
   Confirm the subscription has been completed successfully before moving to the next step running the following command:
   ```
   scripts/00e-cp4i-ckeck-operator-deploy.sh -o cert-manager -n cert-manager-operator
   ```
   You should get a response like this:
   ```
   Check CP4I Operators deployment.
   INFO: Operator Short Name is set to cert-manager
   INFO: Base Namespace is set to cert-manager-operator
   Succeeded
   ```
2. Install Common Services Operator:
   ```
   scripts/00d-cp4i-operators-install.sh -o common-services
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00e-cp4i-ckeck-operator-deploy.sh -o common-services
   ```
   You should get a response like this:
   ```
   Check CP4I Operators deployment.
   INFO: Operator Short Name is set to common-services
   INFO: Base Namespace is set to openshift-operators
   Succeeded
   ```
</details>
&nbsp;

<details>
<summary>
D) Create namespaces with the corresponding entitlement key:
</summary>

1. If do not have a key available already, you can get the key from the [Container software library](https://myibm.ibm.com/products-services/containerlibrary).
2. Set your entitlement key:
   ```
   export ENT_KEY=<my-key>
   ```
3. Create namespaces:
   ```
   scripts/02a-cp4i-ns-key-config.sh
   ```
</details>
&nbsp; 

<details>
<summary>
E) Deploy Platform UI:
</summary>

1. Install Platform UI Operator:
   ```
   scripts/00d-cp4i-operators-install.sh -o cp4i
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following commands:
   ```
   scripts/00e-cp4i-ckeck-operator-deploy.sh -o cp4i
   ```
   You should get a response like this:
   ```
   Check CP4I Operators deployment.
   INFO: Operator Short Name is set to cp4i
   INFO: Base Namespace is set to openshift-operators
   Succeeded
   ```
2. Deploy a Platform UI instance:
   ```
   scripts/03a-platform-navigator-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00g-cp4i-ckeck-instance-deploy.sh -c platformnavigator -i cp4i-navigator
   ```
   You should get a response like this:
   ```
   Check CP4I Capability instance deployment.
   INFO: Base Namespace is set to tools
   INFO: Resource Type is set to platformnavigator
   Ready
   ```
3. Once the Platform UI instance is up and running get the access info:
   ```
   scripts/03b-cp4i-access-info.sh
   ```
   Note the password is temporary and you will be required to change it the first time you log into Platform UI.
</details>
&nbsp;

<details>
<summary>
F) Deploy Asset Repo (optional): 
</summary>

1. Install Asset Repo Operator:
   ```
   scripts/00d-cp4i-operators-install.sh -o asset-repo
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00e-cp4i-ckeck-operator-deploy.sh -o asset-repo
   ```
   You should get a response like this:
   ```
   Check CP4I Operators deployment.
   INFO: Operator Short Name is set to asset-repo
   INFO: Base Namespace is set to openshift-operators
   Succeeded
   ```
2. Deploy an Asset Repo instance:
   ```
   scripts/05-asset-repo-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00g-cp4i-ckeck-instance-deploy.sh -c assetrepository -i asset-repo-ai 
   ```
   You should get a response like this:
   ```
   Check CP4I Capability instance deployment.
   INFO: Base Namespace is set to tools
   INFO: Resource Type is set to assetrepository
   Ready
   ```
</details>
&nbsp;

<details>
<summary>
G) Deploy APIC: 
</summary>

1. Install Mail Server (mailpit):
   1. Deploy Mail Server:
      ```
      scripts/30a-mailpit-deploy-mail-server.sh
      ```
   2. Connect to Mail Server:
      Navigate to URL and use the credentials to access the UI.
2. Install DataPower Operator:
   ```
   scripts/00d-cp4i-operators-install.sh -o datapower
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00e-cp4i-ckeck-operator-deploy.sh -o datapower
   ```
   You should get a response like this:
   ```
   Check CP4I Operators deployment.
   INFO: Operator Short Name is set to datapower
   INFO: Base Namespace is set to openshift-operators
   Succeeded
   ```
3. Install APIC Operator:
   ```
   scripts/00d-cp4i-operators-install.sh -o apiconnect
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```  
   scripts/00e-cp4i-ckeck-operator-deploy.sh -o apiconnect
   ```
   You should get responses like these for both of them:
   ```
   Check CP4I Operators deployment.
   INFO: Operator Short Name is set to apiconnect
   INFO: Base Namespace is set to openshift-operators
   Succeeded
   ```
4. Deploy APIC instance with some extra features enabled:
   ```
   scripts/07d-apic-inst-deploy.sh
   ```
   Confirm the installation completed successfully before moving to the next step running the following commands:
   ```
   scripts/00g-cp4i-ckeck-instance-deploy.sh -c apiconnectcluster -i apim-demo
   ```
   Note this will take almost 30 minutes, so be patient, and at the end you should get a response like this:
   ```
   Check CP4I Capability instance deployment.
   INFO: Base Namespace is set to tools
   INFO: Resource Type is set to apiconnectcluster
   Ready
   ```
5. Configure the email server in APIC:
   ```
   scripts/07f-apic-initial-config.sh
   ```
6. Create a Provider Organization for admin user:
   ```
   scripts/07g-apic-new-porg-cs.sh
   ```
7. Set API Key for post deployment configuration:
      1. Get API Key following instructions listed [here](https://www.ibm.com/docs/en/api-connect/10.0.x?topic=applications-managing-platform-rest-api-keys#taskcapim_mng_apikeys__steps__1)
      2. Set environment variable for API Key:
         ```
         export APIC_API_KEY=<my-apic-api-key>
         ```
8. Create Secret for Assemblies (optional):
      ```
      scripts/07i-apic-secret-cp4i-apikey.sh
      ```
9. Deploy extra API Gateway (optional):
      ```
      scripts/07j-apic-extra-gw-deploy.sh
      ```
      Confirm the instance has been deployed successfully before moving to the next step running the following command:
      ```
      scripts/00g-cp4i-ckeck-instance-deploy.sh -c gatewaycluster -i remote-api-gw -n cp4i-dp
      ```
      You should get responses like these:
      ```
      Check CP4I Capability instance deployment.
      INFO: Base Namespace is set to cp4i-dp
      INFO: Resource Type is set to gatewaycluster
      Running
      ```
10. Add extra gateway to APIC instance (optional):
      1. Get the required info:
         ```
         scripts/07g-apic-extra-dp-info.sh
         ```
      2. Navigate to the APIC CMC clicking on the instance name as shown below: 
         ![APIC CMC Image 0](images/APIC_CMC_Access.png)
      3. Select the `Cloud Pak User Registry` as shown below:
         ![APIC CMC Image 1](images/APIC_CMC_Login.png)
      4. Click on the `Configure Topology` tile as shown below:
         ![APIC CMC Image 2](images/APIC_CMC_Config_Topology.png)
      5. Click the `Register Service` button as shown below:
         ![APIC CMC Image 3](images/APIC_CMC_Reg_Service.png)
      6. Select the `DataPower API Gateway` tile as shown below:
         ![APIC CMC Image 4](images/APIC_CMC_Config_Service.png)
      7. Type the name of the service in the `Title` box, for instance "api-rgw-service" as shown below:
         ![APIC CMC Image 5](images/APIC_CMC_Serv_Details_1.png)
      8. Scroll dowm and paste the `Management Endpoint URL` you got from the first step under the "Service endpoint configuration" section as shown below:
         ![APIC CMC Image 6](images/APIC_CMC_Serv_Details_2.png)
      9. Scroll down and paste the `API Endpoint Base URL` you got from the first step under the "API invocation endpoint" section and click the `Save` button as shown below:
         ![APIC CMC Image 7](images/APIC_CMC_Serv_Details_3.png)
      10. The screen shows the new API Gateway Service in the Topology as shown below:
         ![APIC CMC Image 8](images/APIC_CMC_DP_Registered.png)
         Note you can associate the new API Gateway with the Analytics Service on your own if needed.
</details>
&nbsp; 

<details>
<summary>
H) Deploy Standalone DP Gateway (optional): 
</summary>

1. Deploy DP Gateway instance:
   ```
   scripts/35b-dp-gw-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00g-cp4i-ckeck-instance-deploy.sh -c datapowerservice -i dp-demo -n cp4i-dp
   ```
   You should get a response like this:
   ```
   Check CP4I Capability instance deployment.
   INFO: Base Namespace is set to cp4i-dp
   INFO: Resource Type is set to datapowerservice
   Running
   ```
2. Create networking config to access DP Gateway Web UI:
   ```
   scripts/35a-dp-gw-routes-config.sh
   ```
3. Get the DP Gateway Web UI URL:
   ```
   echo -e "\033[1;33mhttps://$(oc get route dpwebui-route -n cp4i-dp -o jsonpath='{.spec.host}')\033[0m"
   ```
4. Go to your favorite browser and enter the URL.
   *Note*: This is ONLY for demo purposes and show the Web UI but you shouldn't be making changes to a DP Gateway running on containers via the Web UI.
</details>
&nbsp;

<details>
<summary>
I) Deploy Event Streams: 
</summary>

1. Install Event Streams Operator:
   ```
   scripts/00d-cp4i-operators-install.sh -o eventstreams
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00e-cp4i-ckeck-operator-deploy.sh -o eventstreams
   ```
   You should get a response like this:
   ```
   Check CP4I Operators deployment.
   INFO: Operator Short Name is set to eventstreams
   INFO: Base Namespace is set to openshift-operators
   Succeeded
   ```
2. Deploy Event Streams instance:
   ```
   scripts/08a-event-streams-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00g-cp4i-ckeck-instance-deploy.sh -c eventstreams -i es-demo
   ```
   Note this will take few minutes, so be patient, and at some point you may see some errors, but at the end you should get a response like this:
   ```
   Check CP4I Capability instance deployment.
   INFO: Base Namespace is set to tools
   INFO: Resource Type is set to eventstreams
   Ready
   ```
3. Create topics and users:
   ```
   scripts/08b-event-streams-initial-config.sh
   ```
4. Enable Kafka Connect base:
   ```
   scripts/08c-event-streams-kafka-connect-config.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00g-cp4i-ckeck-instance-deploy.sh -c kafkaconnect -i jgr-connect-cluster
   ```
   Note this will take few minutes, but at the end you should get a response like this:
   ```
   Check CP4I Capability instance deployment.
   INFO: Base Namespace is set to tools
   INFO: Resource Type is set to kafkaconnect
   Ready
   ```
</details>
&nbsp; 

<details>
<summary>
J) Deploy Event Endpoint Management - EEM (optional): 
</summary>

1. Install EEM Operator:
   ```
   scripts/00d-cp4i-operators-install.sh -o eem
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00e-cp4i-ckeck-operator-deploy.sh -o eem
   ```
   You should get a response like this:
   ```
   Check CP4I Operators deployment.
   INFO: Operator Short Name is set to eem
   INFO: Base Namespace is set to openshift-operators
   Succeeded
   ```
2. Decide if you will integrate with KeyCloak or if you will use local security. If KeyCloak, set the following environment variable, otherwise go to the next step.
   ```
   export EA_OIDC=YES
   ```
3. Deploy EEM Manager instance:
   ```
   scripts/19a-eem-manager-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00g-cp4i-ckeck-instance-deploy.sh -c eventendpointmanagement -i eem-demo-mgr
   ```
   Note this will take few minutes, so be patient, but at the end you should get a response like this:
   ```
   Check CP4I Capability instance deployment.
   INFO: Base Namespace is set to tools
   INFO: Resource Type is set to eventendpointmanagement
   Running
   ```
4. Deploy EEM Gateway instance:
   ```
   scripts/19b-eem-gateway-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   scripts/00g-cp4i-ckeck-instance-deploy.sh -c eventgateway -i eem-demo-gw
   ```
   Note this will take few minutes, so be patient, but at the end you should get a response like this:
   ```
   Check CP4I Capability instance deployment.
   INFO: Base Namespace is set to tools
   INFO: Resource Type is set to eventgateway
   Running
   ```
</details>
&nbsp; 