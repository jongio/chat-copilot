param name string
param location string = resourceGroup().location
param appServicePlanQdrantId string
param webSubnetId string
param qdrantSubnetId string
param storageFileShareName string
param strorageAccountName string

var strorageAccountId = resourceId(subscription().subscriptionId, resourceGroup().name,
  'Microsoft.Storage/storageAccounts', strorageAccountName)

resource appServiceQdrant 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: appServicePlanQdrantId
    httpsOnly: true
    reserved: true
    clientCertMode: 'Required'
    virtualNetworkSubnetId: qdrantSubnetId
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|qdrant/qdrant:latest'
      alwaysOn: true
      vnetRouteAllEnabled: true
      ipSecurityRestrictions: [
        {
          vnetSubnetResourceId: webSubnetId
          action: 'Allow'
          priority: 300
          name: 'Allow front vnet'
        }
        {
          ipAddress: 'Any'
          action: 'Deny'
          priority: 2147483647
          name: 'Deny all'
        }
      ]
      azureStorageAccounts: {
        aciqdrantshare: {
          type: 'AzureFiles'
          accountName: strorageAccountName
          shareName: storageFileShareName
          mountPath: '/qdrant/storage'
          accessKey: listKeys(strorageAccountId, '2019-06-01').keys[0].value
        }
      }
    }
  }
}

resource qdrantSubnetConnection 'Microsoft.Web/sites/virtualNetworkConnections@2022-09-01' = {
  name: 'qdrantSubnetConnection'
  parent: appServiceQdrant
  properties: {
    vnetResourceId: qdrantSubnetId
    isSwift: true
  }
}

output defaultHost string = appServiceQdrant.properties.defaultHostName
