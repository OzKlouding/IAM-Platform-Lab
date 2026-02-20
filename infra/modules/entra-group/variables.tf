terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
  }
}
variable "display_name" {
  description = "The display name for the group"
  type        = string
}

variable "description" {
  description = "The description for the group"
  type        = string
  default     = null
}

variable "security_enabled" {
  description = "Whether the group is a security group"
  type        = bool
  default     = true
}

variable "mail_enabled" {
  description = "Whether the group is mail-enabled"
  type        = bool
  default     = false
}

variable "mail_nickname" {
  description = "The mail alias for the group"
  type        = string
  default     = null
}

variable "members" {
  description = "List of member object IDs"
  type        = list(string)
  default     = []
}

variable "owners" {
  description = "List of owner object IDs"
  type        = list(string)
  default     = []
}