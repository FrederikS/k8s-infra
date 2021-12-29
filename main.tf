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

resource "kubernetes_role_binding" "developer" {
  metadata {
    name = "role-binding-developer"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "developer"
  }
  subject {
    kind      = "Group"
    name      = "devs"
    api_group = "rbac.authorization.k8s.io"
  }
}

module "user" {
  source         = "./modules/user"
  for_each       = var.users
  name           = each.key
  group          = each.value.group
  cert_directory = var.cert_directory
}
