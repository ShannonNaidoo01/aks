terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "random" {}

# Helm provider configured to use AKS cluster
provider "helm" {
  kubernetes = {
    host                   = module.azurerm-aks.aks_host
    client_certificate     = base64decode(module.azurerm-aks.aks_client_certificate)
    client_key             = base64decode(module.azurerm-aks.aks_client_key)
    cluster_ca_certificate = base64decode(module.azurerm-aks.aks_cluster_ca_certificate)
  }
}

# Kubernetes provider configured to use AKS cluster
provider "kubernetes" {
  host                   = module.azurerm-aks.aks_host
  client_certificate     = base64decode(module.azurerm-aks.aks_client_certificate)
  client_key             = base64decode(module.azurerm-aks.aks_client_key)
  cluster_ca_certificate = base64decode(module.azurerm-aks.aks_cluster_ca_certificate)
}
