
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path    = var.kubernetes_config_path
    config_context = var.kubernetes_context
  }
}

module "istio" {
  source = "./istio"
}

module "k8s-dashboard" {
  source     = "./k8s-dashboard"
  depends_on = [module.istio]
}
