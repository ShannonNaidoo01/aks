# -----------------------------------------------------------------------------
# Azure Entra Groups Module - Outputs
# -----------------------------------------------------------------------------

output "groups" {
  description = "Map of created group details"
  value = {
    for k, v in azuread_group.groups : k => {
      id           = v.id
      object_id    = v.object_id
      display_name = v.display_name
      description  = v.description
    }
  }
}

output "group_ids" {
  description = "Map of group keys to object IDs (for easy reference)"
  value = {
    for k, v in azuread_group.groups : k => v.object_id
  }
}

output "existing_groups" {
  description = "Map of existing group details"
  value = {
    for k, v in data.azuread_group.existing : k => {
      id           = v.id
      object_id    = v.object_id
      display_name = v.display_name
    }
  }
}

output "all_group_ids" {
  description = "Map of all group keys to object IDs (created and existing)"
  value = merge(
    { for k, v in azuread_group.groups : k => v.object_id },
    { for k, v in data.azuread_group.existing : k => v.object_id }
  )
}
