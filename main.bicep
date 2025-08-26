
// Bicep Template for Function App + Staging Slot + Key Vault + Managed Identity
param location string = resourceGroup().location
param functionAppName string
param storageAccountName string
param appServicePlanName string
param keyVaultName string

// Storage Account
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
}

// App Service Plan
resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: { name: 'Y1'; tier: 'Dynamic' }
  kind: 'functionapp'
}

// Function App with Managed Identity
resource functionApp 'Microsoft.Web/sites@2023-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: { type: 'SystemAssigned' }
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVault.name}.vault.azure.net/secrets/AzureWebJobsStorage)'
        }
        {
          name: 'MyDbPassword'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVault.name}.vault.azure.net/secrets/MyDbPassword)'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
  }
}

// Staging Slot
resource stagingSlot 'Microsoft.Web/sites/slots@2023-03-01' = {
  name: '${functionApp.name}/staging'
  location: location
  kind: 'functionapp'
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVault.name}.vault.azure.net/secrets/AzureWebJobsStorage)'
        }
        {
          name: 'MyDbPassword'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVault.name}.vault.azure.net/secrets/MyDbPassword)'
        }
      ]
    }
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-06-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: { family: 'A'; name: 'standard' }
    tenantId: subscription().tenantId
    enablePurgeProtection: true
    enableSoftDelete: true
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: functionApp.identity.principalId
        permissions: {
          secrets: [ 'get', 'list' ]
        }
      }
    ]
  }
}
