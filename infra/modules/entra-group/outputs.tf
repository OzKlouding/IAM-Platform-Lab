output "object_id" {
  description = "The object ID of the group"
  value       = azuread_group.group.object_id
}

output "display_name" {
  description = "The display name of the group"
  value       = azuread_group.group.display_name
}

output "id" {
  description = "The Terraform resource ID"
  value       = azuread_group.group.id
}

output "mail_nickname" {
  description = "The mail nickname of the group"
  value       = azuread_group.group.mail_nickname
}