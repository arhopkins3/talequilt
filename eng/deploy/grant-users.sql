-- Run by the Deploy workflow as the SQL administrator (the deploy identity) after migrations (ADR 0021).
-- Idempotent: creates the Entra users if missing and makes sure they hold their roles.
-- $(AppIdentity): the user-assigned identity the API and worker run as; reads and writes data, no schema rights.
-- $(HumanLogin): Alex's Entra account, db_owner for support; adding a person is a variable change, not code.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$(AppIdentity)')
    CREATE USER [$(AppIdentity)] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [$(AppIdentity)];
ALTER ROLE db_datawriter ADD MEMBER [$(AppIdentity)];

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$(HumanLogin)')
    CREATE USER [$(HumanLogin)] FROM EXTERNAL PROVIDER;
ALTER ROLE db_owner ADD MEMBER [$(HumanLogin)];
GO
