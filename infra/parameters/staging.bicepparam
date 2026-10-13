using '../main.bicep'

// Values that identify the bootstrap-created identity and Alex's Entra account are supplied by the Deploy
// workflow from GitHub environment variables; nothing here is secret.
param environmentName = 'staging'
param appIdentityId = readEnvironmentVariable('APP_IDENTITY_ID')
param appIdentityClientId = readEnvironmentVariable('APP_IDENTITY_CLIENT_ID')
param appIdentityPrincipalId = readEnvironmentVariable('APP_IDENTITY_PRINCIPAL_ID')
param sqlAdminObjectId = readEnvironmentVariable('SQL_ADMIN_OBJECT_ID')
param sqlAdminLogin = readEnvironmentVariable('SQL_ADMIN_LOGIN')
param allowedIpRanges = split(readEnvironmentVariable('ALLOWED_IP_RANGES'), ',')
param apiImage = readEnvironmentVariable('API_IMAGE')
param workerImage = readEnvironmentVariable('WORKER_IMAGE')
param budgetAlertEmail = readEnvironmentVariable('BUDGET_ALERT_EMAIL')
param monthlyBudgetGbp = 10
param apiMinReplicas = 0
