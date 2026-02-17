# Entra ID User Module

Automates user creation in Microsoft Entra ID (Azure AD).

## Usage
```hcl
module "test_user" {
  source = "../../modules/entra-user"
  
  user_principal_name = "john.doe@yourdomain.onmicrosoft.com"
  display_name        = "John Doe"
  password            = "SecurePassword123!"
  job_title           = "Cloud Engineer"
  department          = "IT"
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| user_principal_name | string | yes | User's UPN |
| display_name | string | yes | Display name |
| password | string | yes | Initial password |
| job_title | string | no | Job title |
| department | string | no | Department |

## Outputs

| Name | Description |
|------|-------------|
| object_id | Azure AD object ID |
| user_principal_name | User UPN |
| display_name | Display name |