#!/bin/bash -v
omsWorkspaceName=$1
resourceGroupName=$2
gitHubTemplateUri='https://raw.githubusercontent.com/jfoxva/azure-vmss-updates/master/LogAnalyticsWorkspace.json'
gitHubLogAnalyticsAgentUri='https://raw.githubusercontent.com/jfoxva/azure-vmss-updates/master/oms-daemonset.yaml'
#Get Log Analytics workspaceId and primary key, and deploy Log Analytics agent on the AKS cluster
output=$(az group deployment create --resource-group $resourceGroupName --template-uri $gitHubTemplateUri --parameters workspaceName=$omsWorkspaceName --verbose)
workspaceId=$(echo $output|jq -r .properties.outputs.workspaceId.value)
primaryKey=$(echo $output|jq -r .properties.outputs.primaryKey.value)
workspaceIdEncoded=$(echo $workspaceId|base64 --wrap=0)
primaryKeyEncoded=$(echo $primaryKey|base64 --wrap=0)
echo "apiVersion: v1
data:
  KEY: $primaryKeyEncoded
  WSID: $workspaceIdEncoded
kind: Secret
metadata:
  name: omsagent-secret
  namespace: default
type: Opaque" > omsagent-secret.yaml
kubectl apply -f ./omsagent-secret.yaml
wget $FileLogAnalyticsAgentUri --output-document=oms-daemonset.yaml
kubectl apply -f ./oms-daemonset.yaml