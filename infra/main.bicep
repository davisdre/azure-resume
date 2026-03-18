@description('Location for all resources.')
param location string = resourceGroup().location

@description('A prefix to ensure resource names are globally unique.')
@minLength(1)
@maxLength(20)
param appPrefix string = 'azres${uniqueString(resourceGroup().id)}'

@description('The URL of the frontend application allowed to call the API (used for CORS). E.g. https://resume.davisdre.com')
param frontendUrl string = 'https://resume.davisdre.com'

// Variable declarations for resource names
var storageAccountName = '${appPrefix}stg'
var cosmosDbName = '${appPrefix}db'
var functionAppName = '${appPrefix}func'
var appServicePlanName = '${appPrefix}plan'

// 1. Storage Account (Used for static website hosting and Function App backend storage)
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS' // Basic/cheapest tier
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: true
  }
}

// 2. Cosmos DB (Free Tier enabled)
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosDbName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    enableFreeTier: true // Takes advantage of Azure's free tier offering
  }
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  parent: cosmosDbAccount
  name: 'AzureResume'
  properties: {
    resource: {
      id: 'AzureResume'
    }
  }
}

resource cosmosDbContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: cosmosDbDatabase
  name: 'Counter'
  properties: {
    resource: {
      id: 'Counter'
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
    }
  }
}

// 3. App Service Plan (Consumption Plan / Y1 for Serverless Azure Functions)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1' // Dynamic consumption plan
    tier: 'Dynamic'
  }
}

// 4. Azure Function App (Backend API)
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v8.0' // Explicitly set .NET 8
      use32BitWorkerProcess: false // Run as a 64-bit process for .NET Isolated
      cors: {
        allowedOrigins: [
          frontendUrl
        ]
      }
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated' // .NET 8 requires the isolated worker model
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1' // Forces a clean deployment and ignores old ghost files
        }
        {
          name: 'AzureResumeConnectionString' // Connecting the DB
          value: cosmosDbAccount.listConnectionStrings().connectionStrings[0].connectionString
        }
      ]
    }
  }
}

// Exported Outputs to use in GitHub Actions easily later
output storageAccountName string = storageAccount.name
output functionAppName string = functionApp.name
output staticWebsiteUrl string = storageAccount.properties.primaryEndpoints.web
