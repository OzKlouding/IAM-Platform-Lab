terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
  }
}

provider "azuread" {}

# Get your Azure AD domain
data "azuread_domains" "current" {
  only_initial = true
}

# Create a test user
module "test_user" {
  source = "../.."

  user_principal_name = "testuser-${formatdate("YYYYMMDDhhmmss", timestamp())}@${data.azuread_domains.current.domains[0].domain_name}"
  display_name        = "Test User - IAM Lab"
  password            = "ChangeMe123!Secure"
  job_title           = "Test Engineer"
  department          = "Platform Engineering"
}

output "created_user" {
  value = {
    upn          = module.test_user.user_principal_name
    display_name = module.test_user.display_name
    object_id    = module.test_user.object_id
  }
}