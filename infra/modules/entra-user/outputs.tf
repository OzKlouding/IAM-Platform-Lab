output "object_id" {
  description = "The object ID of the user"
  value       = azuread_user.user.object_id
}

output "user_principal_name" {
  description = "The user principal name"
  value       = azuread_user.user.user_principal_name
}

output "display_name" {
  description = "The display name of the user"
  value       = azuread_user.user.display_name
}

output "id" {
  description = "The Terraform resource ID"
  value       = azuread_user.user.id
}