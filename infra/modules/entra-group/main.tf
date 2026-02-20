data "azuread_client_config" "current" {}

resource "azuread_group" "group" {
  display_name     = var.display_name
  description      = var.description
  security_enabled = var.security_enabled
  mail_enabled     = var.mail_enabled
  mail_nickname    = var.mail_nickname != null ? var.mail_nickname : replace(lower(var.display_name), " ", "-")

  members = var.members
  owners  = length(var.owners) > 0 ? var.owners : [data.azuread_client_config.current.object_id]
}