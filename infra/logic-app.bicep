param appServicePlanName string
param appInsightsName string
param logicAppName string
param location string
param storageAccountName string
param logAnalyticsWorkspaceName string
param kubernetesEnvironmentName string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' existing = {
  name: appServicePlanName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource kubernetesEnvironment 'Microsoft.ExtendedLocation/customLocations@2021-08-15' existing = {
  name: kubernetesEnvironmentName
}

var storageConnectionString = 'DefaultEndpointsProtocol=https;EndpointSuffix=${environment().suffixes.storage};AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'

resource logicApp 'Microsoft.Web/sites@2021-03-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,linux,workflowapp,kubernetes'
  extendedLocation: {
    name: kubernetesEnvironment.id
    type: 'CustomLocation'
  }
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    isXenon: false
    hyperV: false
    scmSiteAlsoStopped: false
    siteConfig: {
      linuxFxVersion: 'NODE|12'
      netFrameworkVersion: 'v4.6'
      alwaysOn: true
      localMySqlEnabled: false
      http20Enabled: true
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITES_PORT'
          value: '80'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'AzureWebJobsStorage'
          value: storageConnectionString
        }
        {
          name: 'AzureWebJobsDashboard'
          value: storageConnectionString
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'false'
        }
      ]
    }
  }
}

resource connection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'office365'
  location: location
  kind: 'V2'
  properties: {
    api: {
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
    }
  }
}

resource accessPolicies 'Microsoft.Web/connections/accessPolicies@2016-06-01' = {
  name: '9e9b8c20-c979-4537-9896-3c9e2d3eef77'
  location: location
  parent: connection
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        objectId: '9e9b8c20-c979-4537-9896-3c9e2d3eef77'
        tenantId: subscription().tenantId
      }
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource logicAppDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: logicApp
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAntivirusScanAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceFileAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output logicAppName string = logicApp.name
output logicAppUrl string = logicApp.properties.defaultHostName
