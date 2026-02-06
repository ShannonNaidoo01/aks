# -----------------------------------------------------------------------------
# Azure Entra Groups Module - Variables
# -----------------------------------------------------------------------------

variable "groups" {
  description = "Map of Azure Entra groups to create and manage"
  type = map(object({
    display_name            = string
    description             = optional(string, "")
    security_enabled        = optional(bool, true)
    mail_enabled            = optional(bool, false)
    mail_nickname           = optional(string, null)
    prevent_duplicate_names = optional(bool, true)
    owners                  = optional(list(string), []) # List of object IDs
    members = optional(object({
      users              = optional(list(string), []) # User principal names or object IDs
      service_principals = optional(list(string), []) # Service principal object IDs or app IDs
      groups             = optional(list(string), []) # Group object IDs
    }), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.groups : !v.mail_enabled || (v.mail_enabled && v.mail_nickname != null)
    ])
    error_message = "mail_nickname is required when mail_enabled is true."
  }
}

variable "existing_groups" {
  description = "Map of existing Azure Entra groups to manage membership for"
  type = map(object({
    display_name = string # Used to look up the existing group
    members = optional(object({
      users              = optional(list(string), []) # User principal names or object IDs
      service_principals = optional(list(string), []) # Service principal object IDs or app IDs
      groups             = optional(list(string), []) # Group object IDs
    }), {})
  }))
  default = {}
}

variable "include_current_user_as_owner" {
  description = "Automatically include the current authenticated user/service principal as an owner of created groups"
  type        = bool
  default     = true
}
