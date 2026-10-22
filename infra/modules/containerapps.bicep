// Container Apps environment with the API (external ingress behind an IP allow-list, ADR 0008 stopgap) and the
// worker (no ingress). Both run as the user-assigned identity; each deploy creates a new revision and the
// Deploy workflow shifts traffic, which is what makes rollback a traffic change (ADR 0021).
param prefix string
param location string
param tags object
param logAnalyticsWorkspaceId string
param appIdentityId string
param appIdentityClientId string
param allowedIpRanges array
param apiImage string
param workerImage string
param apiMinReplicas int
@secure()
param sqlConnectionString string
param storageAccountName string
param keyVaultUri string
@description('Origin of the web app, allowed by the API\'s CORS policy (ADR 0021).')
param webOrigin string

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: last(split(logAnalyticsWorkspaceId, '/'))
}

resource environment 'Microsoft.App/managedEnvironments@2025-01-01' = {
  name: '${prefix}-env'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
  }
}

var commonEnv = [
  { name: 'AZURE_CLIENT_ID', value: appIdentityClientId }
  { name: 'ConnectionStrings__TaleQuilt', secretRef: 'sql-connection-string' }
  { name: 'Storage__AccountName', value: storageAccountName }
  { name: 'KeyVault__Uri', value: keyVaultUri }
  { name: 'Cors__AllowedOrigins__0', value: webOrigin }
  { name: 'ASPNETCORE_FORWARDEDHEADERS_ENABLED', value: 'true' }
]

resource api 'Microsoft.App/containerApps@2025-01-01' = {
  name: '${prefix}-api'
  location: location
  tags: tags
  identity: { type: 'UserAssigned', userAssignedIdentities: { '${appIdentityId}': {} } }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Multiple'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
        allowInsecure: false
        // Every deploy points traffic at the newest revision; a rollback moves it back by hand (ADR 0021).
        traffic: [ { latestRevision: true, weight: 100 } ]
        ipSecurityRestrictions: [for (range, i) in allowedIpRanges: {
          name: 'allow-${i}'
          action: 'Allow'
          ipAddressRange: range
          description: 'ADR 0008 stopgap: allow-listed address until sign-in exists'
        }]
      }
      secrets: [ { name: 'sql-connection-string', value: sqlConnectionString } ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: apiImage
          resources: { cpu: json('0.25'), memory: '0.5Gi' }
          env: commonEnv
          probes: [
            { type: 'Liveness', httpGet: { path: '/api/health', port: 8080 }, initialDelaySeconds: 10, periodSeconds: 30 }
            { type: 'Readiness', httpGet: { path: '/api/health', port: 8080 }, initialDelaySeconds: 5, periodSeconds: 10 }
          ]
        }
      ]
      scale: { minReplicas: apiMinReplicas, maxReplicas: 2 }
    }
  }
}

resource worker 'Microsoft.App/containerApps@2025-01-01' = {
  name: '${prefix}-worker'
  location: location
  tags: tags
  identity: { type: 'UserAssigned', userAssignedIdentities: { '${appIdentityId}': {} } }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: [ { name: 'sql-connection-string', value: sqlConnectionString } ]
    }
    template: {
      containers: [
        {
          name: 'worker'
          image: workerImage
          resources: { cpu: json('0.25'), memory: '0.5Gi' }
          env: commonEnv
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
        rules: [
          {
            // The scaler reads the queue length as the app identity (Storage Queue Data Contributor, granted in
            // storage.bicep): no storage key exists to put in a secret. Needs API 2025-01-01 or later.
            name: 'jobs-queue'
            azureQueue: { accountName: storageAccountName, queueName: 'jobs', queueLength: 1, identity: appIdentityId }
          }
        ]
      }
    }
  }
}

output apiFqdn string = api.properties.configuration.ingress.fqdn
output apiAppName string = api.name
output workerAppName string = worker.name
