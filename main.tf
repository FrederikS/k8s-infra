terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

resource "kubernetes_role" "developer" {
  metadata {
    name = "developer"
  }
  rule {
    api_groups = [""]
    verbs      = ["get", "list"]
    resources  = ["pods"]
  }
}

module "user" {
  source   = "./modules/user"
  for_each = var.users
  name     = each.key
  role     = each.value.role
}
