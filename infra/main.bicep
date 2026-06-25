@description('The location where all resources will be deployed.')
param location string = resourceGroup().location

// 1. Remove the @maxLength(6) restriction completely
@description('Unique suffix appended to resource names to avoid global naming collisions.')
param suffix string = uniqueString(resourceGroup().id)

// 2. Use substring() to safely slice the first 6 characters of the hash
var shortSuffix = substring(suffix, 0, 6)

// 3. Update your variable definitions to use the shortSuffix
var storageName = 'stresume${shortSuffix}'
var cosmosAccountName = 'cosmos-resume-${shortSuffix}'
var functionAppName = 'func-resume-${shortSuffix}'
var hostingPlanName = 'plan-resume-${shortSuffix}'
var appInsightsName = 'insights-resume-${shortSuffix}'

// Dynamically fetches '.core.windows.net' on public Azure, or correct regional variations elsewhere
var storageEndpointSuffix = environment().suffixes.storage
var staticWebsiteUrl = 'https://${storageName}.z13.web.${storageEndpointSuffix}'

// ==========================================
// 1. STORAGE ACCOUNT (Blazor WASM Hosting)
// ==========================================
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// ==========================================
// 2. COSMOS DB (Serverless NoSQL)
// ==========================================
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosAccountName
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
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosAccount
  name: 'ResumeDatabase'
  properties: {
    resource: {
      id: 'ResumeDatabase'
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: database
  name: 'CounterContainer'
  properties: {
    resource: {
      id: 'CounterContainer'
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
    }
  }
}

// ==========================================
// 3. MONITORING & APP INSIGHTS
// ==========================================
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ==========================================
// 4. FUNCTION APP (Serverless .NET 10 Backend)
// ==========================================
resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      netFrameworkVersion: 'v10.0' // Configures the host for .NET 10 execution
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
          value: 'dotnet-isolated'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'CosmosDBConnectionString'
          value: cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString
        }
      ]
      cors: {
        allowedOrigins: [
          'https://localhost:7001' // For local Blazor debug environments
          'http://localhost:5001'
          staticWebsiteUrl        // Replaces the hardcoded web URL cleanly
        ]
      }
    }
    httpsOnly: true
  }
}

// ==========================================
// OUTPUT VALUES FOR THE CI/CD PIPELINE
// ==========================================
output storageAccountName string = storageAccount.name
output functionAppName string = functionApp.name
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
