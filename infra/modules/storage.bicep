// Storage for manuscript blobs and the worker's queue (Phases 5 and 6). Shared keys are off: the apps reach it
// through their managed identity, so there is no account key to leak. Public blob access is off and stays off.
param name string
param location string
param tags object
param appIdentityPrincipalId string

// Built-in role ids: Storage Blob Data Contributor, Storage Queue Data Contributor.
var blobContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var queueContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  // checkov:skip=CKV_AZURE_35: A default-deny network rule needs a VNet or private endpoint for the apps to reach the account; the consumption Container Apps plan has neither. Shared keys are off, so access is identity-only (ADR 0021).
  // checkov:skip=CKV_AZURE_59: Same: the account stays reachable over the public endpoint, with anonymous blob access off and TLS 1.2 required.
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: { name: 'Standard_GRS' }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
    networkAcls: { defaultAction: 'Allow', bypass: 'AzureServices' }
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: true
      services: {
        blob: { enabled: true }
        queue: { enabled: true }
      }
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: account
  name: 'default'
  properties: {
    deleteRetentionPolicy: { enabled: true, days: 14 }
    containerDeleteRetentionPolicy: { enabled: true, days: 14 }
  }
}

resource manuscripts 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'manuscripts'
  properties: { publicAccess: 'None' }
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = {
  parent: account
  name: 'default'
}

resource jobs 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  parent: queueService
  name: 'jobs'
}

resource blobRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(account.id, appIdentityPrincipalId, blobContributor)
  scope: account
  properties: { roleDefinitionId: blobContributor, principalId: appIdentityPrincipalId, principalType: 'ServicePrincipal' }
}

resource queueRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(account.id, appIdentityPrincipalId, queueContributor)
  scope: account
  properties: { roleDefinitionId: queueContributor, principalId: appIdentityPrincipalId, principalType: 'ServicePrincipal' }
}

output storageAccountId string = account.id
output storageAccountName string = account.name
