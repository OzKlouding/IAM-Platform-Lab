#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# bootstrap_state_storage_v2.sh
#
# Purpose:
# - Create (or reuse) an Azure Resource Group
# - Create (or reuse) a Storage Account
# - Create (or reuse) a Blob Container
# - Print Terraform backend values for remote state
#
# Usage:
#   ./scripts/bootstrap_state_storage_v2.sh
#
# Optional env overrides:
#   TF_STATE_RESOURCE_GROUP   (default: rg-iam-tfstate)
#   TF_STATE_LOCATION         (default: eastus)
#   TF_STATE_CONTAINER        (default: tfstate)
#   TF_STATE_STORAGE_ACCOUNT  (default: generated unique name)
#
# Notes:
# - Script derives subscription/tenant from your current Azure CLI context.
# - No hard-coded subscription IDs.
# - Fails fast on missing login or missing permissions.
# -----------------------------------------------------------------------------

# ----------------------------
# Config (override via env vars)
# ----------------------------
RG_NAME="${TF_STATE_RESOURCE_GROUP:-rg-iam-tfstate}"
LOCATION="${TF_STATE_LOCATION:-eastus}"
CONTAINER_NAME="${TF_STATE_CONTAINER:-tfstate}"
SA_NAME="${TF_STATE_STORAGE_ACCOUNT:-}"   # optional; generated if empty

# ----------------------------
# Helpers
# ----------------------------
fail() {
  echo "ERROR: $1"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

validate_sa_name() {
  local name="$1"
  [[ "${#name}" -ge 3 && "${#name}" -le 24 ]] || fail "Storage account name must be 3-24 chars: ${name}"
  [[ "$name" =~ ^[a-z0-9]+$ ]] || fail "Storage account name must be lowercase letters/numbers only: ${name}"
}

# ----------------------------
# Preconditions
# ----------------------------
require_cmd az

if ! az account show >/dev/null 2>&1; then
  fail "Azure CLI is not logged in. Run: az login"
fi

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
ACCOUNT_UPN="$(az account show --query user.name -o tsv 2>/dev/null || true)"

[[ -n "$SUBSCRIPTION_ID" && "$SUBSCRIPTION_ID" != "null" ]] || fail "No active subscription found. Run: az account list -o table"
[[ -n "$TENANT_ID" && "$TENANT_ID" != "null" ]] || fail "No tenantId found in current context."

# Pin the CLI context to what we just read (prevents stale/cached context issues)
az account set --subscription "$SUBSCRIPTION_ID" >/dev/null

# Generate a storage account name if not provided
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

# ----------------------------
# Permission probe
# ----------------------------
# If RG doesn't exist, try to create it. If this fails, permissions are wrong.
echo "Checking permissions..."
if ! az group exists --name "$RG_NAME" >/dev/null 2>&1; then
  if ! az group create --name "$RG_NAME" --location "$LOCATION" >/dev/null 2>&1; then
    fail "No permission to create resource groups in subscription $SUBSCRIPTION_ID. Run as the subscription owner or grant Contributor/Owner."
  fi
fi

# ----------------------------
# Create/ensure Resource Group
# ----------------------------
echo "Creating or updating resource group..."
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION" \
  1>/dev/null

# ----------------------------
# Create/ensure Storage Account
# ----------------------------
echo "Creating or updating storage account (this can take ~30-90s)..."

# Check if storage account exists in the RG
if az storage account show --name "$SA_NAME" --resource-group "$RG_NAME" >/dev/null 2>&1; then
  echo "Storage account already exists: $SA_NAME"
else
  az storage account create \
    --name "$SA_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    1>/dev/null
  echo "Storage account created: $SA_NAME"
fi

# ----------------------------
# Create/ensure Blob Container
# ----------------------------
echo "Creating or updating blob container..."

# Use logged-in identity auth (no keys). Works if you have RBAC on the storage account.
if az storage container show \
  --name "$CONTAINER_NAME" \
  --account-name "$SA_NAME" \
  --auth-mode login \
  >/dev/null 2>&1; then
  echo "Container already exists: $CONTAINER_NAME"
else
  az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$SA_NAME" \
    --auth-mode login \
    1>/dev/null
  echo "Container created: $CONTAINER_NAME"
fi

# ----------------------------
# Output for Terraform backend
# ----------------------------
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

echo "Next:"
echo "1) Put these values into infra/backend.tf (or env vars)"
echo "2) Run: terraform init"

