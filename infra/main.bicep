param appName string
param environment string
param region string
param location string = resourceGroup().location
param kubernetesEnvironmentName string
param kubeEnvironmentProfileName string

module names 'resource-names.bicep' = {
  name: 'resource-names'
  params: {
    appName: appName
    region: region
    env: environment
  }
}

module loggingDeployment 'logging.bicep' = {
  name: 'logging-deployment'
  params: {
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsWorkspaceName
    location: location
    appInsightsName: names.outputs.appInsightsName
  }
}

module storageDeployment 'storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    storageAccountName: names.outputs.storageAccountName
  }
}

module appServicePlanDeployment 'app-service-plan.bicep' = {
  name: 'app-service-plan-deployment'
  params: {
    appServicePlanName: names.outputs.appServicePlanName
    location: location
    kubernetesEnvironmentName: kubernetesEnvironmentName
    kubeEnvironmentProfileName: kubeEnvironmentProfileName
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
  }
}

module logicAppDeployment 'logic-app.bicep' = {
  name: 'logic-app-deployment'
  params: {
    location: location
    storageAccountName: storageDeployment.outputs.storageAccountName
    appServicePlanName: appServicePlanDeployment.outputs.appServicePlanName
    appInsightsName: loggingDeployment.outputs.appInsightsName
    logicAppName: names.outputs.logicAppName
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    kubernetesEnvironmentName: kubernetesEnvironmentName
  }
}
