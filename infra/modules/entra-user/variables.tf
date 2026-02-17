variable "user_principal_name" {
  description = "The user principal name (e.g., john.doe@yourdomain.onmicrosoft.com)"
  type        = string
}

variable "display_name" {
  description = "The display name of the user"
  type        = string
}

variable "password" {
  description = "The initial password for the user"
  type        = string
  sensitive   = true
}

variable "force_password_change" {
  description = "Whether to force password change on first login"
  type        = bool
  default     = true
}

variable "account_enabled" {
  description = "Whether the account is enabled"
  type        = bool
  default     = true
}

variable "job_title" {
  description = "The job title of the user"
  type        = string
  default     = null
}

variable "department" {
  description = "The department of the user"
  type        = string
  default     = null
}