using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'env_name')

param location = readEnvironmentVariable('AZURE_LOCATION', 'location')

param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', 'principal_id')

param azureAdTenantId = readEnvironmentVariable('AZURE_AD_TENANT_ID', '')

param webApiClientId = readEnvironmentVariable('AZURE_BACKEND_APPLICATION_ID', '')

param frontendClientId = readEnvironmentVariable('AZURE_FRONTEND_APPLICATION_ID', '')

param deployWebSearcherPlugin = bool(readEnvironmentVariable('DEPLOY_WEB_SEARCHER_PLUGIN', 'false'))

param deployCosmosDB = bool(readEnvironmentVariable('DEPLOY_COSMOSDB', 'true'))

param deploySpeechServices = bool(readEnvironmentVariable('DEPLOY_SPEECH_SERVICES', 'true'))

param memoryStore = readEnvironmentVariable('MEMORY_STORE', 'AzureCognitiveSearch')
