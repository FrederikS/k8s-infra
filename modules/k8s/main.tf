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

module "helm" {
  source                 = "./helm"
  kubernetes_config_path = var.kubernetes_config_path
  kubernetes_context     = var.kubernetes_context
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

module "httpbin" {
  source = "./httpbin"
}
