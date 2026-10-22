#!/usr/bin/env bash
# One-time bootstrap for one environment (ADR 0021). Run by Alex from his own signed-in Azure CLI session, once
# per environment; everything else is created by infra/main.bicep from the Deploy workflow. This script exists
# because the pipeline cannot create the identity it signs in with.
#
# It creates: the resource group; a user-assigned managed identity for the pipeline, with a federated credential
# that trusts GitHub Actions runs of this repository in the matching GitHub environment and nothing else, holding
# Contributor and Role Based Access Control Administrator on the resource group only; and a second user-assigned
# identity the API and worker run as. It prints the values to put in the GitHub environment as variables.
#
# Safe to re-run: every step creates or updates in place, and the federated credential is corrected if GitHub's
# subject format has changed since it was first created (see the note at that step).
#
# Usage: infra/bootstrap.sh <staging|production> [location]
set -euo pipefail

ENVIRONMENT="${1:?usage: infra/bootstrap.sh <staging|production> [location]}"
LOCATION="${2:-uksouth}"
REPO="arhopkins3/talequilt"
case "$ENVIRONMENT" in staging|production) ;; *) echo "environment must be staging or production" >&2; exit 2;; esac

RG="rg-talequilt-${ENVIRONMENT}"
DEPLOYER="id-talequilt-${ENVIRONMENT}-deploy"
APP="id-talequilt-${ENVIRONMENT}-app"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

echo "Subscription $SUBSCRIPTION_ID, tenant $TENANT_ID, environment $ENVIRONMENT, region $LOCATION"

az group create --name "$RG" --location "$LOCATION" --tags project=talequilt environment="$ENVIRONMENT" managedBy=bootstrap -o none

az identity create --name "$DEPLOYER" --resource-group "$RG" --location "$LOCATION" -o none
az identity create --name "$APP" --resource-group "$RG" --location "$LOCATION" -o none

DEPLOYER_PRINCIPAL="$(az identity show --name "$DEPLOYER" --resource-group "$RG" --query principalId -o tsv)"
DEPLOYER_CLIENT="$(az identity show --name "$DEPLOYER" --resource-group "$RG" --query clientId -o tsv)"
APP_ID="$(az identity show --name "$APP" --resource-group "$RG" --query id -o tsv)"
APP_CLIENT="$(az identity show --name "$APP" --resource-group "$RG" --query clientId -o tsv)"
APP_PRINCIPAL="$(az identity show --name "$APP" --resource-group "$RG" --query principalId -o tsv)"

# The federated credential: GitHub's OIDC issuer, and a subject that names this repository and this GitHub
# environment. A run from another repository, branch or environment presents a different subject and is refused.
# GitHub's immutable subject format (default for repositories created after 15 July 2026, which this one is)
# carries the owner and repository IDs: repo:<owner>@<owner id>/<repo>@<repo id>:environment:<name>. A rename or
# transfer then leaves the subject unchanged. The IDs come from GitHub's public API; the first staging run failed
# with AADSTS700213 because the credential had been created with the older name-only subject.
OWNER="${REPO%%/*}"
NAME="${REPO##*/}"
OWNER_ID="$(az rest --url "https://api.github.com/repos/${REPO}" --skip-authorization-header --query owner.id -o tsv)"
REPO_ID="$(az rest --url "https://api.github.com/repos/${REPO}" --skip-authorization-header --query id -o tsv)"
SUBJECT="repo:${OWNER}@${OWNER_ID}/${NAME}@${REPO_ID}:environment:${ENVIRONMENT}"
echo "Federated credential subject: $SUBJECT"
if az identity federated-credential show --name "github-${ENVIRONMENT}" --identity-name "$DEPLOYER" --resource-group "$RG" -o none 2>/dev/null; then
  CREDENTIAL_VERB=update
else
  CREDENTIAL_VERB=create
fi
az identity federated-credential "$CREDENTIAL_VERB" \
  --name "github-${ENVIRONMENT}" \
  --identity-name "$DEPLOYER" \
  --resource-group "$RG" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "$SUBJECT" \
  --audiences "api://AzureADTokenExchange" -o none

RG_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}"
# Contributor to create resources; Role Based Access Control Administrator so the Bicep can grant the app
# identity its data-plane roles (blob, queue, Key Vault secrets). Both scoped to this resource group only.
az role assignment create --assignee-object-id "$DEPLOYER_PRINCIPAL" --assignee-principal-type ServicePrincipal \
  --role "Contributor" --scope "$RG_SCOPE" -o none
az role assignment create --assignee-object-id "$DEPLOYER_PRINCIPAL" --assignee-principal-type ServicePrincipal \
  --role "Role Based Access Control Administrator" --scope "$RG_SCOPE" -o none

ME_OBJECT_ID="$(az ad signed-in-user show --query id -o tsv)"
ME_LOGIN="$(az ad signed-in-user show --query userPrincipalName -o tsv)"

cat <<SUMMARY

Done. Create the GitHub environment "${ENVIRONMENT}" and set these as environment VARIABLES (none is a secret):

  AZURE_CLIENT_ID            ${DEPLOYER_CLIENT}
  AZURE_TENANT_ID            ${TENANT_ID}
  AZURE_SUBSCRIPTION_ID      ${SUBSCRIPTION_ID}
  AZURE_RESOURCE_GROUP       ${RG}
  APP_IDENTITY_ID            ${APP_ID}
  APP_IDENTITY_CLIENT_ID     ${APP_CLIENT}
  APP_IDENTITY_PRINCIPAL_ID  ${APP_PRINCIPAL}
  SQL_ADMIN_OBJECT_ID        ${ME_OBJECT_ID}        (you; the pipeline makes this account db_owner)
  SQL_ADMIN_LOGIN            ${ME_LOGIN}
  ALLOWED_IP_RANGES          <your public IP>/32   (comma-separated CIDRs; ADR 0008 stopgap)
  BUDGET_ALERT_EMAIL         <your email>

For production, also add yourself as required reviewer on the environment: that is gate G4.

Or, with the GitHub CLI signed in (gh auth login), paste this after filling in the two placeholders:

  gh api --method PUT repos/${REPO}/environments/${ENVIRONMENT} >/dev/null
  gh variable set AZURE_CLIENT_ID           --repo ${REPO} --env ${ENVIRONMENT} --body "${DEPLOYER_CLIENT}"
  gh variable set AZURE_TENANT_ID           --repo ${REPO} --env ${ENVIRONMENT} --body "${TENANT_ID}"
  gh variable set AZURE_SUBSCRIPTION_ID     --repo ${REPO} --env ${ENVIRONMENT} --body "${SUBSCRIPTION_ID}"
  gh variable set AZURE_RESOURCE_GROUP      --repo ${REPO} --env ${ENVIRONMENT} --body "${RG}"
  gh variable set APP_IDENTITY_ID           --repo ${REPO} --env ${ENVIRONMENT} --body "${APP_ID}"
  gh variable set APP_IDENTITY_CLIENT_ID    --repo ${REPO} --env ${ENVIRONMENT} --body "${APP_CLIENT}"
  gh variable set APP_IDENTITY_PRINCIPAL_ID --repo ${REPO} --env ${ENVIRONMENT} --body "${APP_PRINCIPAL}"
  gh variable set SQL_ADMIN_OBJECT_ID       --repo ${REPO} --env ${ENVIRONMENT} --body "${ME_OBJECT_ID}"
  gh variable set SQL_ADMIN_LOGIN           --repo ${REPO} --env ${ENVIRONMENT} --body "${ME_LOGIN}"
  gh variable set ALLOWED_IP_RANGES         --repo ${REPO} --env ${ENVIRONMENT} --body "<your public IP>/32"
  gh variable set BUDGET_ALERT_EMAIL        --repo ${REPO} --env ${ENVIRONMENT} --body "<your email>"
SUMMARY
