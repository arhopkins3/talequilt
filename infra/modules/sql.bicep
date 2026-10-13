// Azure SQL serverless with auto-pause (ADR 0007). Entra-only authentication: no SQL password exists anywhere.
// The apps connect as their managed identity, which the deploy workflow adds as a database user (ADR 0021).
param serverName string
param databaseName string
param location string
param tags object
param adminObjectId string
param adminLogin string
param logAnalyticsWorkspaceId string
param alertEmail string

resource server 'Microsoft.Sql/servers@2023-08-01-preview' = {
  // checkov:skip=CKV_AZURE_113: Private endpoints need a VNet; the consumption Container Apps plan has none. Entra-only auth, TLS 1.2 and auditing are on. Reviewed again in Phase 5 (ADR 0021).
  name: serverName
  location: location
  tags: tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: adminLogin
      sid: adminObjectId
      tenantId: subscription().tenantId
      principalType: 'User'
    }
  }
}

// Container Apps on the consumption plan have no fixed egress address, so the server admits Azure services.
// Phase 5 reviews this against a VNet-integrated environment once there is user data to protect.
resource allowAzure 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: server
  name: 'AllowAllWindowsAzureIps'
  properties: { startIpAddress: '0.0.0.0', endIpAddress: '0.0.0.0' }
}

resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  // checkov:skip=CKV_AZURE_229: Zone redundancy roughly doubles the serverless price for a single-author app; point-in-time restore is the recovery path (ADR 0021).
  // checkov:skip=CKV_AZURE_26: Alert emails are set in the server and database securityAlertPolicies resources below; the check does not see a child declared separately.
  // checkov:skip=CKV_AZURE_27: Same: emailAccountAdmins is true in both policies below.
  parent: server
  name: databaseName
  location: location
  tags: tags
  sku: { name: 'GP_S_Gen5', tier: 'GeneralPurpose', family: 'Gen5', capacity: 1 }
  properties: {
    minCapacity: json('0.5')
    autoPauseDelay: 60
    maxSizeBytes: 2147483648
    zoneRedundant: false
    requestedBackupStorageRedundancy: 'Local'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

resource auditing 'Microsoft.Sql/servers/auditingSettings@2023-08-01-preview' = {
  parent: server
  name: 'default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
    retentionDays: 90
  }
}

resource databaseAuditing 'Microsoft.Sql/servers/databases/auditingSettings@2023-08-01-preview' = {
  parent: database
  name: 'default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
    retentionDays: 90
  }
}

resource securityAlerts 'Microsoft.Sql/servers/securityAlertPolicies@2023-08-01-preview' = {
  parent: server
  name: 'Default'
  properties: {
    state: 'Enabled'
    disabledAlerts: []
    emailAccountAdmins: true
    emailAddresses: [ alertEmail ]
    retentionDays: 90
  }
}

resource databaseSecurityAlerts 'Microsoft.Sql/servers/databases/securityAlertPolicies@2023-08-01-preview' = {
  parent: database
  name: 'Default'
  properties: {
    state: 'Enabled'
    disabledAlerts: []
    emailAccountAdmins: true
    emailAddresses: [ alertEmail ]
    retentionDays: 90
  }
}

// checkov:skip=CKV_AZURE_23: Reference to the existing master database so audit events can be routed to Log Analytics; not a database this template creates.
// checkov:skip=CKV_AZURE_25: Same reference; threat protection and alerts are set on the server above.
resource masterDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' existing = {
  parent: server
  name: 'master'
}

resource auditToLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'audit'
  scope: masterDb
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [ { category: 'SQLSecurityAuditEvents', enabled: true } ]
  }
}

resource threatProtection 'Microsoft.Sql/servers/advancedThreatProtectionSettings@2023-08-01-preview' = {
  parent: server
  name: 'Default'
  properties: { state: 'Enabled' }
}

resource vulnerabilityAssessment 'Microsoft.Sql/servers/sqlVulnerabilityAssessments@2023-08-01-preview' = {
  parent: server
  name: 'default'
  properties: { state: 'Enabled' }
}

output serverFqdn string = server.properties.fullyQualifiedDomainName
output databaseName string = database.name
// Authentication=Active Directory Default lets the app use its user-assigned identity (AZURE_CLIENT_ID) with no secret.
output connectionString string = 'Server=tcp:${server.properties.fullyQualifiedDomainName},1433;Database=${database.name};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
