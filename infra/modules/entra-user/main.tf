# Create the Entra ID user
resource "azuread_user" "user" {
  user_principal_name = var.user_principal_name
  display_name        = var.display_name
  mail_nickname       = split("@", var.user_principal_name)[0]

  password              = var.password
  force_password_change = var.force_password_change

  account_enabled = var.account_enabled

  job_title  = var.job_title
  department = var.department

  lifecycle {
    ignore_changes = [
      password,
    ]
  }
}