terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

module "roles" {
  source = "./roles"
}

module "user" {
  source   = "./user"
  for_each = var.kubernetes_users
  name     = each.key
  group    = each.value.group
}
