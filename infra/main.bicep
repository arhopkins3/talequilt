// TaleQuilt infrastructure for one environment (ADR 0007, ADR 0021). Deployed at resource-group scope by the
// Deploy workflow, signed in through OpenID Connect as that environment's managed identity. The resource group,
// the two managed identities and their federated credentials are the only things made outside this template,
// by infra/bootstrap.sh, because the pipeline cannot create the identity it signs in with.
//
// Same template for staging and production; the differences live in infra/parameters/*.bicepparam.
targetScope = 'resourceGroup'

@description('Environment name, used in resource names and tags: staging or production.')
@allowed(['staging', 'production'])
param environmentName string

@description('Azure region. UK South per ADR 0007.')
param location string = resourceGroup().location

@description('Resource id of the user-assigned managed identity the API and worker run as (created by bootstrap.sh).')
param appIdentityId string

@description('Client id of that identity, passed to the apps so they can sign in to SQL, Storage and Key Vault without a secret.')
param appIdentityClientId string

@description('Principal (object) id of that identity, for role assignments.')
param appIdentityPrincipalId string

@description('Entra object id of the SQL server administrator (Alex). Entra-only authentication; no SQL passwords exist.')
param sqlAdminObjectId string

@description('Sign-in name shown for the SQL administrator, for example an email address.')
param sqlAdminLogin string

@description('IP ranges allowed to reach the API, in CIDR. The ADR 0008 stopgap until sign-in exists in Phase 5.')
param allowedIpRanges array

@description('Container image for the API, for example ghcr.io/arhopkins3/talequilt-api:sha-abc1234.')
param apiImage string

@description('Container image for the worker.')
param workerImage string

@description('Email address for budget alerts.')
param budgetAlertEmail string

@description('Monthly budget in GBP; alerts fire at 50 and 100 percent.')
param monthlyBudgetGbp int = 20

@description('Minimum replicas for the API. 0 scales to zero when idle (staging); 1 keeps production warm.')
@minValue(0)
@maxValue(1)
param apiMinReplicas int = 0

var prefix = 'talequilt-${environmentName}'
var tags = {
  project: 'talequilt'
  environment: environmentName
  managedBy: 'bicep'
}

module logs 'modules/logs.bicep' = {
  name: 'logs'
  params: { name: '${prefix}-logs', location: location, tags: tags }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: toLower(replace('tq${environmentName}${uniqueString(resourceGroup().id)}', '-', ''))
    location: location
    tags: tags
    appIdentityPrincipalId: appIdentityPrincipalId
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyVault'
  params: {
    name: 'tq-${environmentName}-${substring(uniqueString(resourceGroup().id), 0, 8)}'
    location: location
    tags: tags
    appIdentityPrincipalId: appIdentityPrincipalId
    logAnalyticsWorkspaceId: logs.outputs.workspaceId
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    serverName: '${prefix}-sql-${substring(uniqueString(resourceGroup().id), 0, 6)}'
    databaseName: 'talequilt'
    location: location
    tags: tags
    adminObjectId: sqlAdminObjectId
    adminLogin: sqlAdminLogin
    logAnalyticsWorkspaceId: logs.outputs.workspaceId
    alertEmail: budgetAlertEmail
  }
}

module apps 'modules/containerapps.bicep' = {
  name: 'apps'
  params: {
    prefix: prefix
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logs.outputs.workspaceId
    appIdentityId: appIdentityId
    appIdentityClientId: appIdentityClientId
    allowedIpRanges: allowedIpRanges
    apiImage: apiImage
    workerImage: workerImage
    apiMinReplicas: apiMinReplicas
    sqlConnectionString: sql.outputs.connectionString
    storageAccountName: storage.outputs.storageAccountName
    keyVaultUri: keyVault.outputs.vaultUri
    webOrigin: 'https://${web.outputs.defaultHostname}'
  }
}

module web 'modules/staticwebapp.bicep' = {
  name: 'web'
  params: { name: '${prefix}-web', tags: tags }
}

module budget 'modules/budget.bicep' = {
  name: 'budget'
  params: { name: '${prefix}-budget', amountGbp: monthlyBudgetGbp, alertEmail: budgetAlertEmail }
}

output apiFqdn string = apps.outputs.apiFqdn
output apiAppName string = apps.outputs.apiAppName
output workerAppName string = apps.outputs.workerAppName
output webDefaultHostname string = web.outputs.defaultHostname
output webAppName string = web.outputs.name
output sqlServerFqdn string = sql.outputs.serverFqdn
output sqlDatabaseName string = sql.outputs.databaseName
output keyVaultName string = keyVault.outputs.name
output storageAccountName string = storage.outputs.storageAccountName
