#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Bootstrap Terraform remote state storage in Azure
# -----------------------------------------------------------------------------
RG_NAME="${TF_STATE_RESOURCE_GROUP:-rg-iam-tfstate}"
LOCATION="${TF_STATE_LOCATION:-eastus}"
CONTAINER_NAME="${TF_STATE_CONTAINER:-tfstate}"
SA_NAME="${TF_STATE_STORAGE_ACCOUNT:-}"

fail() { echo "ERROR: $1"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

validate_sa_name() {
  local name="$1"
  [[ "${#name}" -ge 3 && "${#name}" -le 24 ]] || fail "Storage account name must be 3-24 chars: ${name}"
  [[ "$name" =~ ^[a-z0-9]+$ ]] || fail "Storage account name must be lowercase letters/numbers only: ${name}"
}

require_cmd az

# Must be logged in
if ! az account show >/dev/null 2>&1; then
  fail "Azure CLI is not logged in. Run: az login"
fi

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
ACCOUNT_UPN="$(az account show --query user.name -o tsv 2>/dev/null || true)"

[[ -n "$SUBSCRIPTION_ID" && "$SUBSCRIPTION_ID" != "null" ]] || fail "No active subscription found. Run: az account list -o table"
[[ -n "$TENANT_ID" && "$TENANT_ID" != "null" ]] || fail "No tenantId found in current context."

# Pin context and also pass subscription on every call
az account set --subscription "$SUBSCRIPTION_ID" >/dev/null
AZ_SUB="--subscription $SUBSCRIPTION_ID"

# Force subscription context for all Azure CLI commands (Windows Git Bash fix)
export AZURE_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"


# Generate SA name if not provided
if [[ -z "$SA_NAME" ]]; then
  SA_NAME="iamtfstate${RANDOM}${RANDOM}"
fi
validate_sa_name "$SA_NAME"

echo ""
echo "Using account: ${ACCOUNT_UPN:-unknown}"
echo "Using tenant:  ${TENANT_ID}"
echo "Using sub:     ${SUBSCRIPTION_ID}"
echo "RG:            ${RG_NAME}"
echo "Location:      ${LOCATION}"
echo "Storage acct:  ${SA_NAME}"
echo "Container:     ${CONTAINER_NAME}"
echo ""

# Permission probe
echo "Checking permissions..."
if ! az group exists $AZ_SUB --name "$RG_NAME" >/dev/null 2>&1; then
  if ! az group create $AZ_SUB --name "$RG_NAME" --location "$LOCATION" -o none >/dev/null 2>&1; then
    fail "No permission to create resource groups in subscription $SUBSCRIPTION_ID."
  fi
fi

echo "Creating or updating resource group..."
az group create $AZ_SUB --name "$RG_NAME" --location "$LOCATION" -o none

echo "Creating or updating storage account..."

SA_URL="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Storage/storageAccounts/${SA_NAME}?api-version=2023-01-01"

# Exists check via ARM REST
SA_EXISTS="$(az rest --method get --url "$SA_URL" --query "name" -o tsv 2>/dev/null || true)"

if [[ -n "$SA_EXISTS" && "$SA_EXISTS" != "null" ]]; then
  echo "Storage account already exists: $SA_NAME"
else
  az rest --method put --url "$SA_URL" --body "{
    \"location\": \"${LOCATION}\",
    \"kind\": \"StorageV2\",
    \"sku\": { \"name\": \"Standard_LRS\" },
    \"properties\": {
      \"allowBlobPublicAccess\": false,
      \"minimumTlsVersion\": \"TLS1_2\"
    }
  }" -o none
  echo "Storage account create requested: $SA_NAME"
  echo "DEBUG: Using ARM REST for storage account"
fi

# Get a storage context, prefer Entra auth, fallback to account key if needed
AUTH_MODE="login"
SA_KEY=""

if ! az storage container list \
  --account-name "$SA_NAME" \
  --auth-mode login \
  -o none >/dev/null 2>&1; then

  # Try to acquire an account key as fallback (requires control-plane permissions)
  SA_KEY="$(az storage account keys list $AZ_SUB \
    --resource-group "$RG_NAME" \
    --account-name "$SA_NAME" \
    --query "[0].value" -o tsv 2>/dev/null || true)"

  if [[ -n "$SA_KEY" ]]; then
    AUTH_MODE="key"
  fi
fi

echo "Creating or updating blob container..."

if [[ "$AUTH_MODE" == "login" ]]; then
  if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$SA_NAME" \
    --auth-mode login \
    -o none >/dev/null 2>&1; then
    echo "Container already exists: $CONTAINER_NAME"
  else
    az storage container create \
      --name "$CONTAINER_NAME" \
      --account-name "$SA_NAME" \
      --auth-mode login \
      -o none
    echo "Container created: $CONTAINER_NAME"
  fi
else
  if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$SA_NAME" \
    --account-key "$SA_KEY" \
    -o none >/dev/null 2>&1; then
    echo "Container already exists: $CONTAINER_NAME"
  else
    az storage container create \
      --name "$CONTAINER_NAME" \
      --account-name "$SA_NAME" \
      --account-key "$SA_KEY" \
      -o none
    echo "Container created: $CONTAINER_NAME"
  fi
fi


echo ""
echo "----------------------------------------"
echo "Terraform remote state values"
echo "----------------------------------------"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
echo "TF_STATE_RESOURCE_GROUP=$RG_NAME"
echo "TF_STATE_STORAGE_ACCOUNT=$SA_NAME"
echo "TF_STATE_CONTAINER=$CONTAINER_NAME"
echo "----------------------------------------"
echo ""
