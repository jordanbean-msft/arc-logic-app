# Vars
#$natip="x.x.x.x" #optional if you need to specify Public IP (This is useful if your cluster will deploy services with an Internal IP Address)
$groupName="<RG_NAME>"
$workspaceName="<Existing Log Analytics Workspace Name>"
$logAnalyticsWorkspaceId=$(az monitor log-analytics workspace show `
    --resource-group $groupName `
    --workspace-name $workspaceName `
    --query customerId `
    --output tsv)
$logAnalyticsWorkspaceIdEnc=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($logAnalyticsWorkspaceId))# Needed for the next step
$logAnalyticsKey=$(az monitor log-analytics workspace get-shared-keys `
    --resource-group $groupName `
    --workspace-name $workspaceName `
    --query primarySharedKey `
    --output tsv)
$logAnalyticsKeyEnc=[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($logAnalyticsKey))

$clusterName="<Arc-Enabled Cluster Name>"
$extensionName="<Name for Appsvc Extension to be installed>" # Name of the App Service extension
$namespace="<K8s namespace to install extension to>" # Namespace in your cluster to install the extension and provision resources
$kubeEnvironmentName="<Name for Kube Environment>" # Name of the App Service Kubernetes environment resource
$customLocationName="<Name for the Custom Location to get created>" # Name of the custom location


# Create App Service Extension on Arc-Enabled Cluster
az k8s-extension create `
    --resource-group $groupName `
    --name $extensionName `
    --cluster-type connectedClusters `
    --cluster-name $clusterName `
    --extension-type 'Microsoft.Web.Appservice' `
    --release-train stable `
    --auto-upgrade-minor-version true `
    --scope cluster `
    --release-namespace $namespace `
    --configuration-settings "Microsoft.CustomLocation.ServiceAccount=default" `
    --configuration-settings "appsNamespace=${namespace}" `
    --configuration-settings "clusterName=${kubeEnvironmentName}" `
    --configuration-settings "keda.enabled=true" `
    --configuration-settings "buildService.storageClassName=default" `
    --configuration-settings "buildService.storageAccessMode=ReadWriteOnce" `
    --configuration-settings "customConfigMap=${namespace}/kube-environment-config" `
    --configuration-settings "envoy.annotations.service.beta.kubernetes.io/azure-load-balancer-resource-group=${aksClusterGroupName}" `
    --configuration-settings "logProcessor.appLogs.destination=log-analytics" `
    --configuration-protected-settings "logProcessor.appLogs.logAnalyticsConfig.customerId=${logAnalyticsWorkspaceIdEnc}" `
    --configuration-protected-settings "logProcessor.appLogs.logAnalyticsConfig.sharedKey=${logAnalyticsKeyEnc}"

$extensionId=$(az k8s-extension show `
    --cluster-type connectedClusters `
    --cluster-name $clusterName `
    --resource-group $groupName `
    --name $extensionName `
    --query id `
    --output tsv)

az resource wait --ids $extensionId --custom "properties.installState!='Pending'" --api-version "2020-07-01-preview"

$connectedClusterId=$(az connectedk8s show --resource-group $groupName --name $clusterName --query id --output tsv)


# Create Custome Location to deploy Apps to
az customlocation create `
    --resource-group $groupName `
    --name $customLocationName `
    --host-resource-id $connectedClusterId `
    --namespace $namespace `
    --cluster-extension-ids $extensionId

$customLocationId=$(az customlocation show `
    --resource-group $groupName `
    --name $customLocationName `
    --query id `
    --output tsv)

az appservice kube create `
    --resource-group $groupName `
    --name $kubeEnvironmentName `
    --custom-location $customLocationId #` Optional if using a staic IP definition
    #--static-ip $natip