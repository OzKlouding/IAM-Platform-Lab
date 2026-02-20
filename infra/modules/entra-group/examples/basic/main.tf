terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
  }
}

provider "azuread" {}

# Get Azure AD domain
data "azuread_domains" "current" {
  only_initial = true
}

# Create a test user using the entra-user module
module "test_user" {
  source = "../../../entra-user"

  user_principal_name = "grouptest-${formatdate("YYYYMMDDhhmmss", timestamp())}@${data.azuread_domains.current.domains[0].domain_name}"
  display_name        = "Group Test User"
  password            = "ChangeMe123!Secure"
  job_title           = "Cloud Engineer"
  department          = "Platform Engineering"
}

# Create a group and add the user
module "test_group" {
  source = "../.."

  display_name     = "Cloud Engineers - Test Group"
  description      = "Test group for IAM Platform Lab"
  security_enabled = true
  members          = [module.test_user.object_id]
}

# Outputs
output "created_user" {
  value = {
    upn       = module.test_user.user_principal_name
    object_id = module.test_user.object_id
  }
}

output "created_group" {
  value = {
    display_name = module.test_group.display_name
    object_id    = module.test_group.object_id
  }
}
