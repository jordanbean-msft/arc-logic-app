param location string
param appServicePlanName string
param kubernetesEnvironmentName string
param kubeEnvironmentProfileName string
param logAnalyticsWorkspaceName string

resource kubernetesEnvironment 'Microsoft.ExtendedLocation/customLocations@2021-08-15' existing = {
  name: kubernetesEnvironmentName
}

resource kubeEnvironmentProfile 'Microsoft.Web/kubeEnvironments@2022-03-01' existing = {
  name: kubeEnvironmentProfileName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux,kubernetes'
  extendedLocation: {
    name: kubernetesEnvironment.id
    type: 'CustomLocation'
  }
  sku: {
    name: 'K1'
    tier: 'Kubernetes'
    capacity: 1
  }
  properties: {
    reserved: true
    isXenon: false
    perSiteScaling: true
    kubeEnvironmentProfile: {
      id: kubeEnvironmentProfile.id
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: appServicePlan
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output appServicePlanName string = appServicePlan.name
