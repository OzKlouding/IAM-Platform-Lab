#!/usr/bin/env bash
set -euo pipefail

RG_NAME="${TF_STATE_RESOURCE_GROUP:-rg-iam-tfstate}"
LOCATION="${TF_STATE_LOCATION:-eastus}"
SA_NAME="${TF_STATE_STORAGE_ACCOUNT:-iamtfstate$RANDOM$RANDOM}"
CONTAINER_NAME="${TF_STATE_CONTAINER:-tfstate}"

echo "Creating resource group: ${RG_NAME}"
az group create --name "${RG_NAME}" --location "${LOCATION}" 1>/dev/null

echo "Creating storage account: ${SA_NAME}"
az storage account create \
  --name "${SA_NAME}" \
  --resource-group "${RG_NAME}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  1>/dev/null

echo "Creating blob container: ${CONTAINER_NAME}"
ACCOUNT_KEY="$(az storage account keys list --account-name "${SA_NAME}" --resource-group "${RG_NAME}" --query "[0].value" -o tsv)"
az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${SA_NAME}" \
  --account-key "${ACCOUNT_KEY}" \
  1>/dev/null

echo ""
echo "Terraform state storage created."
echo "Export these values or store them as GitHub variables:"
echo "TF_STATE_RESOURCE_GROUP=${RG_NAME}"
echo "TF_STATE_STORAGE_ACCOUNT=${SA_NAME}"
echo "TF_STATE_CONTAINER=${CONTAINER_NAME}"
