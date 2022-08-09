param appName string
param region string
param env string

output appInsightsName string = 'ai-${appName}-${region}-${env}'
output logAnalyticsWorkspaceName string = 'la-${appName}-${region}-${env}'
output storageAccountName string = toLower('sa${appName}${region}${env}')
output appServicePlanName string = 'asp-${appName}-${region}-${env}'
output logicAppName string = 'logic-${appName}-${region}-${env}'
