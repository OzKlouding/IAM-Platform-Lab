#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config (override via env vars)
# -----------------------------
RG_NAME="${TF_STATE_RESOURCE_GROUP:-rg-iam-tfstate}"
LOCATION="${TF_STATE_LOCATION:-eastus}"
CONTAINER_NAME="${TF_STATE_CONTAINER:-tfstate}"

# Storage account naming rules:
# - 3 to 24 characters
# - lowercase letters and numbers only
# - globally unique
DEFAULT_SA_NAME="iamtfstate$RANDOM$RANDOM"
SA_NAME="${TF_STATE_STORAGE_ACCOUNT:-$DEFAULT_SA_NAME}"

# -----------------------------
# Helpers
# -----------------------------
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

# -----------------------------
# Preconditions
# -----------------------------
require_cmd az

# Confirm Azure login
if ! az account show >/dev/null 2>&1; then
  fail "Not logged into Azure. Run: az login"
fi

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"

validate_sa_name "${SA_NAME}"

echo "Using subscription: ${SUBSCRIPTION_ID}"
echo "Using tenant: ${TENANT_ID}"
echo "Resource group: ${RG_NAME}"
echo "Location: ${LOCATION}"
echo "Storage account: ${SA_NAME}"
echo "Container: ${CONTAINER_NAME}"
echo ""

# -----------------------------
# Create RG
# -----------------------------
echo "Creating or updating resource group..."
az group create \
  --name "${RG_NAME}" \
  --location "${LOCATION}" \
  1>/dev/null

# -----------------------------
# Create Storage Account
# -----------------------------
echo "Creating storage account (or confirming it exists)..."
if ! az storage account show --name "${SA_NAME}" --resource-group "${RG_NAME}" >/dev/null 2>&1; then
  az storage account create \
    --name "${SA_NAME}" \
    --resource-group "${RG_NAME}" \
    --location "${LOCATION}" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    1>/dev/null
else
  echo "Storage account already exists, skipping create."
fi

# -----------------------------
# Create Container
# Bootstrap uses account key to create the container reliably.
# Later you can shift to RBAC auth.
# -----------------------------
echo "Creating blob container (or confirming it exists)..."
ACCOUNT_KEY="$(az storage account keys list \
  --account-name "${SA_NAME}" \
  --resource-group "${RG_NAME}" \
  --query "[0].value" -o tsv)"

az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${SA_NAME}" \
  --account-key "${ACCOUNT_KEY}" \
  1>/dev/null

echo ""
echo "Done."
echo ""
echo "Set these as GitHub Actions Variables:"
echo "AZURE_TENANT_ID=${TENANT_ID}"
echo "AZURE_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}"
echo "TF_STATE_RESOURCE_GROUP=${RG_NAME}"
echo "TF_STATE_STORAGE_ACCOUNT=${SA_NAME}"
echo "TF_STATE_CONTAINER=${CONTAINER_NAME}"
