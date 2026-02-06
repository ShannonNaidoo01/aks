# -----------------------------------------------------------------------------
# Azure Entra Groups Module
# -----------------------------------------------------------------------------
# Creates and manages Azure Entra (Azure AD) security groups and membership.
# Supports both creating new groups and managing membership of existing groups.
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azuread_client_config" "current" {}

# Look up existing groups by display name
data "azuread_group" "existing" {
  for_each = var.existing_groups

  display_name     = each.value.display_name
  security_enabled = true
}

# -----------------------------------------------------------------------------
# Flatten member lists for easier iteration
# -----------------------------------------------------------------------------

locals {
  # Current user/SP object ID for owner assignment
  current_object_id = data.azuread_client_config.current.object_id

  # Flatten members for created groups
  group_user_members = flatten([
    for group_key, group in var.groups : [
      for user in try(group.members.users, []) : {
        group_key = group_key
        user      = user
      }
    ]
  ])

  group_sp_members = flatten([
    for group_key, group in var.groups : [
      for sp in try(group.members.service_principals, []) : {
        group_key = group_key
        sp        = sp
      }
    ]
  ])

  group_group_members = flatten([
    for group_key, group in var.groups : [
      for nested_group in try(group.members.groups, []) : {
        group_key    = group_key
        nested_group = nested_group
      }
    ]
  ])

  # Flatten members for existing groups
  existing_group_user_members = flatten([
    for group_key, group in var.existing_groups : [
      for user in try(group.members.users, []) : {
        group_key = group_key
        user      = user
      }
    ]
  ])

  existing_group_sp_members = flatten([
    for group_key, group in var.existing_groups : [
      for sp in try(group.members.service_principals, []) : {
        group_key = group_key
        sp        = sp
      }
    ]
  ])

  existing_group_group_members = flatten([
    for group_key, group in var.existing_groups : [
      for nested_group in try(group.members.groups, []) : {
        group_key    = group_key
        nested_group = nested_group
      }
    ]
  ])
}

# -----------------------------------------------------------------------------
# Look up users by UPN (if not already object IDs)
# -----------------------------------------------------------------------------

data "azuread_user" "members" {
  for_each = toset(concat(
    [for m in local.group_user_members : m.user],
    [for m in local.existing_group_user_members : m.user]
  ))

  # Support both UPN and object ID
  user_principal_name = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", each.value)) ? null : each.value
  object_id           = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", each.value)) ? each.value : null
}

# -----------------------------------------------------------------------------
# Look up service principals
# -----------------------------------------------------------------------------

data "azuread_service_principal" "members" {
  for_each = toset(concat(
    [for m in local.group_sp_members : m.sp],
    [for m in local.existing_group_sp_members : m.sp]
  ))

  # Support both object ID and application (client) ID
  object_id = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", each.value)) ? each.value : null
  client_id = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", each.value)) ? null : each.value
}

# -----------------------------------------------------------------------------
# Create Groups
# -----------------------------------------------------------------------------

resource "azuread_group" "groups" {
  for_each = var.groups

  display_name            = each.value.display_name
  description             = each.value.description
  security_enabled        = each.value.security_enabled
  mail_enabled            = each.value.mail_enabled
  mail_nickname           = each.value.mail_nickname
  prevent_duplicate_names = each.value.prevent_duplicate_names

  # Include current user/SP as owner if enabled
  owners = distinct(concat(
    var.include_current_user_as_owner ? [local.current_object_id] : [],
    each.value.owners
  ))
}

# -----------------------------------------------------------------------------
# Manage Membership for Created Groups
# -----------------------------------------------------------------------------

# Add users to created groups
resource "azuread_group_member" "user_members" {
  for_each = {
    for m in local.group_user_members : "${m.group_key}-${m.user}" => m
  }

  group_object_id  = azuread_group.groups[each.value.group_key].id
  member_object_id = data.azuread_user.members[each.value.user].object_id
}

# Add service principals to created groups
resource "azuread_group_member" "sp_members" {
  for_each = {
    for m in local.group_sp_members : "${m.group_key}-${m.sp}" => m
  }

  group_object_id  = azuread_group.groups[each.value.group_key].id
  member_object_id = data.azuread_service_principal.members[each.value.sp].object_id
}

# Add nested groups to created groups
resource "azuread_group_member" "group_members" {
  for_each = {
    for m in local.group_group_members : "${m.group_key}-${m.nested_group}" => m
  }

  group_object_id  = azuread_group.groups[each.value.group_key].id
  member_object_id = each.value.nested_group
}

# -----------------------------------------------------------------------------
# Manage Membership for Existing Groups
# -----------------------------------------------------------------------------

# Add users to existing groups
resource "azuread_group_member" "existing_user_members" {
  for_each = {
    for m in local.existing_group_user_members : "${m.group_key}-${m.user}" => m
  }

  group_object_id  = data.azuread_group.existing[each.value.group_key].id
  member_object_id = data.azuread_user.members[each.value.user].object_id
}

# Add service principals to existing groups
resource "azuread_group_member" "existing_sp_members" {
  for_each = {
    for m in local.existing_group_sp_members : "${m.group_key}-${m.sp}" => m
  }

  group_object_id  = data.azuread_group.existing[each.value.group_key].id
  member_object_id = data.azuread_service_principal.members[each.value.sp].object_id
}

# Add nested groups to existing groups
resource "azuread_group_member" "existing_group_members" {
  for_each = {
    for m in local.existing_group_group_members : "${m.group_key}-${m.nested_group}" => m
  }

  group_object_id  = data.azuread_group.existing[each.value.group_key].id
  member_object_id = each.value.nested_group
}
