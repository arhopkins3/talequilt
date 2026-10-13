// Key Vault for runtime secrets that are not Azure identities (the image provider key in Phase 6). RBAC
// authorisation, soft delete and purge protection on; the apps' identity can read secrets and nothing else.
param name string
param location string
param tags object
param appIdentityPrincipalId string
param logAnalyticsWorkspaceId string

// Built-in role id: Key Vault Secrets User.
var secretsUser = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  // checkov:skip=CKV_AZURE_109: A firewall rule set would block the Container Apps, which have no fixed egress address on the consumption plan; access is RBAC-only to one identity (ADR 0021).
  // checkov:skip=CKV_AZURE_189: Disabling public access needs a private endpoint and a VNet; reviewed again in Phase 5 with the first real secret.
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    networkAcls: { defaultAction: 'Allow', bypass: 'AzureServices' }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'audit'
  scope: vault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [ { categoryGroup: 'audit', enabled: true } ]
  }
}

resource secretsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, appIdentityPrincipalId, secretsUser)
  scope: vault
  properties: { roleDefinitionId: secretsUser, principalId: appIdentityPrincipalId, principalType: 'ServicePrincipal' }
}

output name string = vault.name
output vaultUri string = vault.properties.vaultUri
