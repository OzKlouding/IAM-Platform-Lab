terraform {
  backend "azurerm" {
    resource_group_name  = "rg-iam-tfstate"
    storage_account_name = "iamtfstate882613872"
    container_name       = "tfstate"
    key                  = "iam-platform-lab.tfstate"
  }
}