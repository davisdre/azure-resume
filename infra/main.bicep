@description('Location for all resources.')
param location string = resourceGroup().location

@description('A prefix to ensure resource names are globally unique.')
@minLength(1)
@maxLength(20)
param appPrefix string = 'azres${uniqueString(resourceGroup().id)}'

@description('The URL of the frontend application allowed to call the API (used for CORS). E.g. https://resume.davisdre.com')
param frontendUrl string = 'https://resume.davisdre.com'

@description('Whether to enable Free Tier for Cosmos DB.')
param enableFreeTier bool = true

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
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false // Hardened: Disabling public access (Resolves #23)
    allowSharedKeyAccess: false // Hardened: Disabling account key-based access
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
    enableFreeTier: enableFreeTier // Use parameter to manage free tier across environments
    disableLocalAuth: true // Hardened: Disabling account key-based access for Cosmos DB
    disableKeyBasedMetadataWriteAccess: true // Hardened: Restrict access to data plane
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
  identity: {
    type: 'SystemAssigned'
  }
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
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        // Removed WEBSITE_CONTENTAZUREFILECONNECTIONSTRING and WEBSITE_CONTENTSHARE 
        // to support identity-based access and harden security.
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
          name: 'AzureResumeConnectionString__accountEndpoint'
          value: cosmosDbAccount.properties.documentEndpoint
        }
      ]
    }
  }
}

// Role Assignments for Managed Identity
var storageBlobDataOwnerId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var storageTableDataContributorId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
var storageQueueDataContributorId = '974c5e8b-45b9-4653-ba55-5f855dd0fb88'

resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, storageBlobDataOwnerId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataOwnerId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource tableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, storageTableDataContributorId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageTableDataContributorId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource queueRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, functionApp.id, storageQueueDataContributorId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageQueueDataContributorId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Cosmos DB SQL Role Assignment for Data Plane access
resource cosmosSqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(cosmosDbAccount.id, functionApp.id, '00000000-0000-0000-0000-000000000002')
  parent: cosmosDbAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosDbName, '00000000-0000-0000-0000-000000000002')
    principalId: functionApp.identity.principalId
    scope: cosmosDbAccount.id
  }
}

// Exported Outputs to use in GitHub Actions easily later
output storageAccountName string = storageAccount.name
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}/api/GetResumeCounter'
output staticWebsiteUrl string = storageAccount.properties.primaryEndpoints.web
