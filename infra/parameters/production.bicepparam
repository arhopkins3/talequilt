using '../main.bicep'

// Values that identify the bootstrap-created identities are supplied by the Deploy workflow, from GitHub
// environment variables and from the deploy identity it signed in as; nothing here is secret.
param environmentName = 'production'
param appIdentityId = readEnvironmentVariable('APP_IDENTITY_ID')
param appIdentityClientId = readEnvironmentVariable('APP_IDENTITY_CLIENT_ID')
param appIdentityPrincipalId = readEnvironmentVariable('APP_IDENTITY_PRINCIPAL_ID')
param sqlAdminObjectId = readEnvironmentVariable('DEPLOYER_PRINCIPAL_ID')
param sqlAdminLogin = readEnvironmentVariable('DEPLOYER_IDENTITY_NAME')
param allowedIpRanges = split(readEnvironmentVariable('ALLOWED_IP_RANGES'), ',')
param apiImage = readEnvironmentVariable('API_IMAGE')
param workerImage = readEnvironmentVariable('WORKER_IMAGE')
param budgetAlertEmail = readEnvironmentVariable('BUDGET_ALERT_EMAIL')
param monthlyBudgetGbp = 20
param apiMinReplicas = 1
