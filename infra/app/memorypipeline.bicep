param name string
param location string = resourceGroup().location
param tags object = {}
param aiService string = 'AzureOpenAI'
param completionModel string = 'gpt-35-turbo'
param embeddingModel string = 'text-embedding-ada-002'
param memoryStore string
param appServicePlanId string
param appInsightsConnectionString string
param azureCognitiveSearch string
param openAIServiceName string
param openAIEndpoint string
param storageAccountName string
param virtualNetworkId0 string
param appServiceQdrantDefaultHostName string
param ocrAccountEndpoint string
param ocrAccountName string

var openAIId = resourceId(subscription().subscriptionId, resourceGroup().name,
  'Microsoft.CognitiveServices/accounts', openAIServiceName)
var storageAccountId = resourceId(subscription().subscriptionId, resourceGroup().name,
  'Microsoft.Storage/storageAccounts', storageAccountName)
var ocrAccountId = resourceId(subscription().subscriptionId, resourceGroup().name,
  'Microsoft.CognitiveServices/accounts', ocrAccountName)

resource appServiceMemoryPipeline 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  kind: 'app'
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    virtualNetworkSubnetId: memoryStore == 'Qdrant' ? virtualNetworkId0 : null
    siteConfig: {
      alwaysOn: true
    }
  }
}

resource appServiceMemoryPipelineConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'web'
  parent: appServiceMemoryPipeline
  properties: {
    alwaysOn: true
    detailedErrorLoggingEnabled: true
    minTlsVersion: '1.2'
    netFrameworkVersion: 'v7.0'
    use32BitWorkerProcess: false
    vnetRouteAllEnabled: true
    appSettings: concat([
      {
        name: 'KernelMemory:ContentStorageType'
        value: 'AzureBlobs'
      }
      {
        name: 'KernelMemory:TextGeneratorType'
        value: aiService
      }
      {
        name: 'KernelMemory:ImageOcrType'
        value: 'AzureFormRecognizer'
      }
      {
        name: 'KernelMemory:DataIngestion:OrchestrationType'
        value: 'Distributed'
      }
      {
        name: 'KernelMemory:DataIngestion:DistributedOrchestration:QueueType'
        value: 'AzureQueue'
      }
      {
        name: 'KernelMemory:DataIngestion:EmbeddingGeneratorTypes:0'
        value: aiService
      }
      {
        name: 'KernelMemory:DataIngestion:VectorDbTypes:0'
        value: memoryStore
      }
      {
        name: 'KernelMemory:Retrieval:VectorDbType'
        value: memoryStore
      }
      {
        name: 'KernelMemory:Retrieval:EmbeddingGeneratorType'
        value: aiService
      }
      {
        name: 'KernelMemory:Services:AzureBlobs:Auth'
        value: 'ConnectionString'
      }
      {
        name: 'KernelMemory:Services:AzureBlobs:ConnectionString'
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[1].value}'
      }
      {
        name: 'KernelMemory:Services:AzureBlobs:Container'
        value: 'chatmemory'
      }
      {
        name: 'KernelMemory:Services:AzureQueue:Auth'
        value: 'ConnectionString'
      }
      {
        name: 'KernelMemory:Services:AzureQueue:ConnectionString'
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2019-06-01').keys[1].value}'
      }
      {
        name: 'KernelMemory:Services:AzureCognitiveSearch:Auth'
        value: 'ApiKey'
      }
      {
        name: 'KernelMemory:Services:AzureCognitiveSearch:Endpoint'
        value: memoryStore == 'AzureCognitiveSearch' ? 'https://${azureCognitiveSearch}.search.windows.net' : ''
      }
      {
        name: 'KernelMemory:Services:AzureCognitiveSearch:APIKey'
        value: memoryStore == 'AzureCognitiveSearch' ? listAdminKeys('Microsoft.Search/searchServices/${azureCognitiveSearch}', '2021-04-01-preview').primaryKey : ''
      }
      {
        name: 'KernelMemory:Services:Qdrant:Endpoint'
        value: memoryStore == 'Qdrant' ? 'https://${appServiceQdrantDefaultHostName}' : ''
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIText:Auth'
        value: 'ApiKey'
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIText:Endpoint'
        value: openAIEndpoint
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIText:APIKey'
        value: listKeys(openAIId, '2023-05-01').key1
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIText:Deployment'
        value: completionModel
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIEmbedding:Auth'
        value: 'ApiKey'
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIEmbedding:Endpoint'
        value: openAIEndpoint
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIEmbedding:APIKey'
        value: listKeys(openAIId, '2023-05-01').key1
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIEmbedding:Deployment'
        value: embeddingModel
      }
      {
        name: 'KernelMemory:Services:AzureFormRecognizer:Auth'
        value: 'ApiKey'
      }
      {
        name: 'KernelMemory:Services:AzureFormRecognizer:Endpoint'
        value: ocrAccountEndpoint
      }
      {
        name: 'KernelMemory:Services:AzureFormRecognizer:APIKey'
        value: listKeys(ocrAccountId, '2023-05-01').key1
      }
      {
        name: 'KernelMemory:Services:OpenAI:TextModel'
        value: completionModel
      }
      {
        name: 'KernelMemory:Services:OpenAI:EmbeddingModel'
        value: embeddingModel
      }
      {
        name: 'KernelMemory:Services:OpenAI:APIKey'
        value: listKeys(openAIId, '2023-05-01').key1
      }
      {
        name: 'Logging:LogLevel:Default'
        value: 'Information'
      }
      {
        name: 'Logging:LogLevel:AspNetCore'
        value: 'Warning'
      }
      {
        name: 'Logging:ApplicationInsights:LogLevel:Default'
        value: 'Warning'
      }
      {
        name: 'ApplicationInsights:ConnectionString'
        value: appInsightsConnectionString
      }
    ])
  }
  dependsOn: [
    memSubnetConnection
  ]
}

resource memSubnetConnection 'Microsoft.Web/sites/virtualNetworkConnections@2022-09-01' = if (memoryStore == 'Qdrant') {
  name: 'memSubnetConnection'
  parent: appServiceMemoryPipeline
  properties: {
    vnetResourceId: memoryStore == 'Qdrant' ? virtualNetworkId0 : null
    isSwift: true
  }
}

output name string = appServiceMemoryPipeline.name
