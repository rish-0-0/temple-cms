#!/usr/bin/env bash
# One-time bootstrap. Run locally after `az login` to create:
#   1. Resource group + storage account for Terraform state
#   2. Azure AD App Registration with GitHub OIDC federated credentials
#   3. Contributor role assignment on the subscription
#
# Outputs the values you need to paste into GitHub Actions Secrets/Variables.
# Idempotent — safe to re-run.

set -euo pipefail

# ---- Edit these to match your setup ----
PROJECT="divyakatha"
LOCATION="centralindia"
GITHUB_OWNER="${GITHUB_OWNER:?set GITHUB_OWNER to your GitHub username/org}"
GITHUB_REPO="${GITHUB_REPO:-temple-cms}"
# ----------------------------------------

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

STATE_RG="rg-${PROJECT}-tfstate"
STATE_SA="${PROJECT}tfstate$(echo -n "$SUBSCRIPTION_ID" | sha256sum | cut -c1-5)"
STATE_CONTAINER="tfstate"
APP_NAME="github-actions-${PROJECT}"

echo "==> Creating tfstate resource group + storage account"
az group create -n "$STATE_RG" -l "$LOCATION" -o none
az storage account create \
  -g "$STATE_RG" -n "$STATE_SA" -l "$LOCATION" \
  --sku Standard_LRS --kind StorageV2 \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 -o none
az storage container create \
  --account-name "$STATE_SA" -n "$STATE_CONTAINER" \
  --auth-mode login -o none

echo "==> Creating App Registration + Service Principal for GitHub Actions"
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [ -z "$APP_ID" ]; then
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
fi

SP_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)
if [ -z "$SP_ID" ]; then
  SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
fi

echo "==> Assigning Contributor + User Access Administrator on subscription"
az role assignment create \
  --assignee "$APP_ID" --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" -o none 2>/dev/null || true
# Needed because Terraform itself creates role assignments (webapp → key vault).
az role assignment create \
  --assignee "$APP_ID" --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" -o none 2>/dev/null || true

echo "==> Granting data-plane access to the tfstate storage account (for AAD-auth backend)"
STATE_SA_ID=$(az storage account show -g "$STATE_RG" -n "$STATE_SA" --query id -o tsv)
az role assignment create \
  --assignee "$APP_ID" --role "Storage Blob Data Contributor" \
  --scope "$STATE_SA_ID" -o none 2>/dev/null || true

echo "==> Registering the Azure resource providers Terraform will use"
for ns in Microsoft.Storage Microsoft.KeyVault Microsoft.Web Microsoft.DBforPostgreSQL Microsoft.CertificateRegistration Microsoft.DomainRegistration Microsoft.ManagedIdentity Microsoft.Authorization; do
  az provider register --namespace "$ns" --subscription "$SUBSCRIPTION_ID" -o none 2>/dev/null || true
done

echo "==> Adding federated credentials for the repo (main branch + PRs)"
add_fic() {
  local name=$1 subject=$2
  az ad app federated-credential create --id "$APP_ID" --parameters "$(cat <<JSON
{
  "name": "$name",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "$subject",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
)" -o none 2>/dev/null || true
}
add_fic "gha-main"                    "repo:${GITHUB_OWNER}/${GITHUB_REPO}:ref:refs/heads/main"
add_fic "gha-pull-requests"           "repo:${GITHUB_OWNER}/${GITHUB_REPO}:pull_request"
add_fic "gha-environment-production"  "repo:${GITHUB_OWNER}/${GITHUB_REPO}:environment:Production"

cat <<EOF

==============================================================
Bootstrap complete. Set these as GitHub Actions Variables:
   AZURE_CLIENT_ID         = $APP_ID
   AZURE_TENANT_ID         = $TENANT_ID
   AZURE_SUBSCRIPTION_ID   = $SUBSCRIPTION_ID
   TFSTATE_RG              = $STATE_RG
   TFSTATE_SA              = $STATE_SA
   TFSTATE_CONTAINER       = $STATE_CONTAINER

And these as GitHub Actions Secrets (generate Strapi secrets via:
  node -e 'const c=require("crypto");const b=n=>c.randomBytes(n).toString("base64");
   console.log(JSON.stringify({
     STRAPI_APP_KEYS:[b(16),b(16),b(16),b(16)].join(","),
     STRAPI_API_TOKEN_SALT:b(16),STRAPI_ADMIN_JWT_SECRET:b(32),
     STRAPI_TRANSFER_TOKEN_SALT:b(16),STRAPI_JWT_SECRET:b(32),
     STRAPI_ENCRYPTION_KEY:b(32)
   },null,2))'
):
   STRAPI_APP_KEYS
   STRAPI_API_TOKEN_SALT
   STRAPI_ADMIN_JWT_SECRET
   STRAPI_TRANSFER_TOKEN_SALT
   STRAPI_JWT_SECRET
   STRAPI_ENCRYPTION_KEY
   GHCR_USERNAME    (your GitHub username)
   GHCR_TOKEN       (PAT with read:packages scope)
==============================================================
EOF
