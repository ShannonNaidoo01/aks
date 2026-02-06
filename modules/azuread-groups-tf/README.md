# Azure Entra Groups Module

Creates and manages Azure Entra (formerly Azure AD) security groups and membership.

## Features

- Create new security groups with configurable settings
- Manage membership of both created and existing groups
- Support for user, service principal, and nested group membership
- Flexible member lookup (UPN for users, app ID or object ID for service principals)
- Automatic owner assignment for created groups

## Usage

### Create New Groups with Members

```hcl
module "entra_groups" {
  source = "./modules/azuread-groups-tf"

  groups = {
    aks-admins = {
      display_name = "AKS Cluster Administrators"
      description  = "Users with admin access to AKS clusters"
      members = {
        users = [
          "alice@tune.exchange",
          "bob@tune.exchange",
        ]
      }
    }

    developers = {
      display_name = "TuneExchange Developers"
      description  = "Development team members"
      members = {
        users = [
          "dev1@tune.exchange",
          "dev2@tune.exchange",
        ]
        groups = [
          module.entra_groups.group_ids["aks-admins"]  # Nested group
        ]
      }
    }
  }
}
```

### Manage Existing Group Membership

```hcl
module "entra_groups" {
  source = "./modules/azuread-groups-tf"

  existing_groups = {
    platform-team = {
      display_name = "Platform Team"  # Must match existing group name
      members = {
        users = [
          "newmember@tune.exchange",
        ]
        service_principals = [
          "00000000-0000-0000-0000-000000000000"  # App/client ID or object ID
        ]
      }
    }
  }
}
```

### Mixed: Create and Manage Existing

```hcl
module "entra_groups" {
  source = "./modules/azuread-groups-tf"

  groups = {
    new-team = {
      display_name = "New Team"
      members = {
        users = ["user@tune.exchange"]
      }
    }
  }

  existing_groups = {
    legacy-team = {
      display_name = "Legacy Team"
      members = {
        users = ["newuser@tune.exchange"]
      }
    }
  }
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `groups` | Map of Azure Entra groups to create | `map(object)` | `{}` |
| `existing_groups` | Map of existing groups to manage membership | `map(object)` | `{}` |
| `include_current_user_as_owner` | Include authenticated user as group owner | `bool` | `true` |

### Group Object Structure

```hcl
{
  display_name            = string           # Required
  description             = string           # Optional, default ""
  security_enabled        = bool             # Optional, default true
  mail_enabled            = bool             # Optional, default false
  mail_nickname           = string           # Required if mail_enabled
  prevent_duplicate_names = bool             # Optional, default true
  owners                  = list(string)     # Optional, object IDs
  members = {
    users              = list(string)        # UPNs or object IDs
    service_principals = list(string)        # App IDs or object IDs
    groups             = list(string)        # Object IDs
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `groups` | Full details of created groups |
| `group_ids` | Map of created group keys to object IDs |
| `existing_groups` | Details of referenced existing groups |
| `all_group_ids` | Map of all group keys to object IDs |

## Permissions Required

The service principal or user running Terraform needs:

- `Group.ReadWrite.All` - To create groups and manage membership
- `GroupMember.ReadWrite.All` - Alternative for membership management only
- `User.Read.All` - To look up users by UPN
- `Application.Read.All` - To look up service principals

## Notes

- Group names must be unique when `prevent_duplicate_names` is true (default)
- Members can be specified by UPN (users) or object ID/app ID (service principals)
- Removing a member from the configuration will remove them from the group
- The module does not manage members added outside of Terraform
