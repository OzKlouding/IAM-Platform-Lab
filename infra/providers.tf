terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "2165db07-24f3-41bf-bfb4-e23d1592a926"
  tenant_id       = "1fe6627a-1c16-44b7-b01f-e1b9c21fcb0d"
}