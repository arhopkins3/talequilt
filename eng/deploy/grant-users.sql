-- Run by the Deploy workflow as the SQL administrator (the deploy identity) after migrations (ADR 0021).
-- Idempotent: creates the Entra users if missing and makes sure they hold their roles.
-- Users are created by identifier (SID), not looked up by name: the caller is a service principal, and a service
-- principal cannot resolve names in Microsoft Graph unless the SQL server has a managed identity with directory
-- rights. CREATE USER ... WITH SID, TYPE = E skips that lookup, so the server needs no identity. Per the CREATE
-- USER documentation the SID is the client ID for a managed identity and the object ID for a person.
-- $(AppIdentity) / $(AppClientId): the user-assigned identity the API and worker run as; reads and writes data, no schema rights.
-- $(HumanLogin) / $(HumanObjectId): Alex's Entra account, db_owner for support; adding a person is a variable change, not code.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$(AppIdentity)')
BEGIN
    DECLARE @appSid VARBINARY(16) = CONVERT(VARBINARY(16), CONVERT(UNIQUEIDENTIFIER, N'$(AppClientId)'));
    DECLARE @appCmd NVARCHAR(MAX) = N'CREATE USER [$(AppIdentity)] WITH SID = ' + CONVERT(NVARCHAR(MAX), @appSid, 1) + N', TYPE = E;';
    EXEC (@appCmd);
END;
ALTER ROLE db_datareader ADD MEMBER [$(AppIdentity)];
ALTER ROLE db_datawriter ADD MEMBER [$(AppIdentity)];
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$(HumanLogin)')
BEGIN
    DECLARE @humanSid VARBINARY(16) = CONVERT(VARBINARY(16), CONVERT(UNIQUEIDENTIFIER, N'$(HumanObjectId)'));
    DECLARE @humanCmd NVARCHAR(MAX) = N'CREATE USER [$(HumanLogin)] WITH SID = ' + CONVERT(NVARCHAR(MAX), @humanSid, 1) + N', TYPE = E;';
    EXEC (@humanCmd);
END;
ALTER ROLE db_owner ADD MEMBER [$(HumanLogin)];
GO
