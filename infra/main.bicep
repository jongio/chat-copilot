targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string
param resourceGroupName string = ''
param openAIServiceName string = ''
param openAISkuName string = 'S0'
param embeddingDeploymentName string = 'text-embedding-ada-002'
param embeddingModelName string = 'text-embedding-ada-002'
param embeddingDeploymentCapacity int = 30
param chatGptDeploymentName string = 'gpt-35-turbo'
param chatGptDeploymentCapacity int = 30
param chatGptModelName string = 'gpt-35-turbo'
param chatGptModelVersion string = '0613'
param webAppName string = ''
param appServicePlanName string = ''
param applicationInsightsName string = ''
param dashboardName string = ''
param logAnalyticsName string = ''
param webApiName string = ''
param storageAccountName string = ''
param azureCognitiveSearchName string = ''
param functionAppWeb string = ''
param appServiceMemoryPipelineName string = ''
param appServiceQdrantName string = ''
param storageFileShareName string = 'aciqdrantshare'
param cosmosDbAccountName string = ''
param speechName string = ''
param azureAdTenantId string = ''
param frontendClientId string = ''
param webApiClientId string = ''

@description('Location of the websearcher plugin to deploy')
#disable-next-line no-hardcoded-env-urls
param webSearcherPackageUri string = 'https://aka.ms/copilotchat/websearcher/latest'

@allowed([ 'B1', 'S1', 'S2', 'S3', 'P1V3', 'P2V3', 'I1V2', 'I2V2' ])
param webAppServiceSku string = 'B1'

@allowed([
  'AzureCognitiveSearch'
  'Qdrant'
])
param memoryStore string = 'AzureCognitiveSearch'

@description('Whether to deploy the web searcher plugin, which requires a Bing resource')
param deployWebSearcherPlugin bool = false

@description('Whether to deploy pre-built binary packages to the cloud')
param deployWebSearcherPackages bool = false

@description('Whether to deploy Cosmos DB for persistent chat storage')
param deployCosmosDB bool = false

@description('Whether to deploy Azure Speech Services to enable input by voice')
param deploySpeechServices bool = false

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module openAI './core/ai/cognitiveservices.bicep' = {
  name: 'openai'
  scope: rg
  params: {
    location: location
    name: !empty(openAIServiceName) ? openAIServiceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    tags: tags
    sku: {
      name: openAISkuName
    }
    deployments: [
      {
        name: chatGptDeploymentName
        model: {
          format: 'OpenAI'
          name: chatGptModelName
          version: chatGptModelVersion
        }
        capacity: chatGptDeploymentCapacity
      }
      {
        name: embeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: embeddingModelName
        }
        capacity: embeddingDeploymentCapacity
      }
    ]
  }
}

module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'asp-webapi'
  scope: rg
  params: {
    location: location
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    sku: {
      name: webAppServiceSku
    }
    kind: 'app'
    reserved: false
  }
}

module api './app/api.bicep' = {
  scope: rg
  name: 'api'
  params: {
    name: !empty(webApiName) ? webApiName : '${abbrs.webSitesAppService}webapi-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'api' }, { skweb: '1' })
    appInsightsConnectionString: applicationInsights.outputs.connectionString
    appServicePlanId: appServicePlan.outputs.id
    azureCognitiveSearch: memoryStore == 'AzureCognitiveSearch' ? azureCognitiveSearch.outputs.name : ''
    openAIEndpoint: openAI.outputs.endpoint
    openAIServiceName: openAI.outputs.name
    strorageAccount: storage.outputs.name
    deployWebSearcherPlugin: deployWebSearcherPlugin
    functionAppWebSearcherPlugin: deployWebSearcherPlugin ? functionAppWebSearcherPlugin.outputs.name : ''
    searcherPluginDefaultHostName: deployWebSearcherPlugin ? functionAppWebSearcherPlugin.outputs.defaulthost : ''
    allowedOrigins: [ '*' ]
    memoryStore: memoryStore
    virtualNetworkId0: memoryStore == 'Qdrant' ? virtualNetwork.outputs.id0 : ''
    appServiceQdrantDefaultHost: memoryStore == 'Qdrant' ? appServiceQdrant.outputs.defaultHost : ''
    deployCosmosDB: deployCosmosDB
    cosmosConnectString: deployCosmosDB ? cosmos.outputs.cosmosConnectString : ''
    deploySpeechServices: deploySpeechServices
    speechAccount: deploySpeechServices ? speechAccount.outputs.name : ''
    azureAdTenantId: azureAdTenantId
    frontendClientId: frontendClientId
    webApiClientId: webApiClientId
  }
}

module web './core/host/staticwebapp.bicep' = {
  scope: rg
  name: 'web'
  params: {
    name: !empty(webAppName) ? webAppName : '${abbrs.webStaticSites}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
  }
}

module storage 'app/storage.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    location: location
    memoryStore: memoryStore
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    storageFileShareName: storageFileShareName
  }
}

module azureCognitiveSearch 'core/search/search-services.bicep' = if (memoryStore == 'AzureCognitiveSearch') {
  scope: rg
  name: 'azurecognitivesearch'
  params: {
    name: !empty(azureCognitiveSearchName) ? azureCognitiveSearchName : '${abbrs.searchSearchServices}${resourceToken}'
    location: location
    replicaCount: 1
    partitionCount: 1
    sku: {
      name: 'basic'
    }
  }
}

module applicationInsights 'core/monitor/applicationinsights.bicep' = {
  name: 'applicatininsight'
  scope: rg
  params: {
    dashboardName: dashboardName
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    name: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    location: location
    includeDashboard: false
  }
}

module logAnalytics 'core/monitor/loganalytics.bicep' = {
  name: 'loganalytics'
  scope: rg
  params: {
    name: !empty(logAnalyticsName) ? logAnalyticsName : 'log-${resourceToken}'
    location: location
  }
}

module functionAppWebSearcherPlugin './app/searcherplugin.bicep' = if (deployWebSearcherPlugin) {
  scope: rg
  name: 'searcherplugin'
  params: {
    name: !empty(functionAppWeb) ? functionAppWeb : '${abbrs.webSitesFunctions}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'searcherplugin' }, { skweb: '1' })
    appInsightsInstrumentationKey: applicationInsights.outputs.instrumentationKey
    appServicePlanId: appServicePlan.outputs.id
    strorageAccount: storage.outputs.name
    deployPackages: deployWebSearcherPackages
    webSearcherPackageUri: webSearcherPackageUri
  }
}

module virtualNetwork 'app/virtualnetwork.bicep' = if (memoryStore == 'Qdrant') {
  scope: rg
  name: 'virtualnetwork'
  params: {
    location: location
  }
}

module appServiceMemoryPipeline 'app/memorypipeline.bicep' = {
  scope: rg
  name: 'appservicememorypipeline'
  params: {
    name: !empty(appServiceMemoryPipelineName) ? appServiceMemoryPipelineName : '${abbrs.webSitesAppService}app-${resourceToken}-memorypipeline'
    location: location
    tags: union(tags, { 'azd-service-name': 'memorypipeline' }, { skweb: '1' })
    appServicePlanId: appServicePlan.outputs.id
    memoryStore: memoryStore
    virtualNetworkId0: memoryStore == 'Qdrant' ? virtualNetwork.outputs.id0 : ''
    appInsightsConnectionString: applicationInsights.outputs.connectionString
    azureCognitiveSearch: memoryStore == 'Qdrant' ? '' : azureCognitiveSearch.outputs.name
    openAIEndpoint: openAI.outputs.name
    openAIServiceName: openAI.outputs.name
    strorageAccount: storage.outputs.name
    appServiceQdrantDefaultHostName: memoryStore == 'Qdrant' ? appServiceQdrant.outputs.defaultHost : ''
  }
}

module appServicePlanQdrant 'core/host/appserviceplan.bicep' = if (memoryStore == 'Qdrant') {
  scope: rg
  name: 'asp-qdrant'
  params: {
    kind: 'linux'
    location: location
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}qdrant-${resourceToken}'
    sku: {
      name: 'P1v3'
    }
  }
}

module appServiceQdrant 'app/qdrant.bicep' = if (memoryStore == 'Qdrant') {
  scope: rg
  name: 'appserviceqdrant'
  params: {
    location: location
    appServicePlanQdrantId: memoryStore == 'Qdrant' ? appServicePlanQdrant.outputs.id : ''
    name: !empty(appServiceQdrantName) ? appServiceQdrantName : '${abbrs.webSitesAppService}qdrant-${resourceToken}'
    storageFileShareName: storageFileShareName
    strorageAccount: storage.outputs.name
    virtualNetworkId0: memoryStore == 'Qdrant' ? virtualNetwork.outputs.id0 : ''
    virtualNetworkId1: memoryStore == 'Qdrant' ? virtualNetwork.outputs.id1 : ''
  }
}

module cosmos 'app/cosmosdb.bicep' = if (deployCosmosDB) {
  scope: rg
  name: 'cosmosdb'
  params: {
    location: location
    name: !empty(cosmosDbAccountName) ? cosmosDbAccountName : 'cosmos-${resourceToken}'
  }
}

module speechAccount 'app/speech.bicep' = if (deploySpeechServices) {
  scope: rg
  name: 'speech'
  params: {
    location: location
    name: !empty(speechName) ? speechName : 'speech-${resourceToken}'
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output AZURE_STORAGE_NAME string = storage.outputs.name
output REACT_APP_BACKEND_URI string = api.outputs.url
output REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output REACT_APP_WEB_BASE_URL string = web.outputs.uri
output AZURE_AD_TENANT_ID string = azureAdTenantId
output AZURE_BACKEND_APPLICATION_ID string = webApiClientId
output AZURE_FRONTEND_APPLICATION_ID string = frontendClientId
output WEB_SEARCHER_PACKAGE_URL string = webSearcherPackageUri
output DEPLOY_WEB_SEARCHER_PLUGIN bool = deployWebSearcherPlugin
output DEPLOY_WEB_SEARCHER_PACKAGES bool = deployWebSearcherPackages
output DEPLOY_COSMOSDB bool = deployCosmosDB
output DEPLOY_SPEECH_SERVICES bool = deploySpeechServices
output MEMORY_STORE string = memoryStore
output AZURE_PLUGIN_NAME array = concat(
  [],
  (deployWebSearcherPlugin) ? [ functionAppWebSearcherPlugin.outputs.name ] : []
)
