terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

module "helm" {
  source                      = "./helm"
  kubernetes_config_path      = var.kubernetes_config_path
  kubernetes_context          = var.kubernetes_context
  certmanager_aws_credentials = var.certmanager_aws_credentials
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

module "serviceaccounts" {
  source       = "./serviceaccounts"
  github_token = var.github_token
}
