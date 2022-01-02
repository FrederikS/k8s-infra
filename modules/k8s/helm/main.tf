
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

module "cert-manager" {
  source                      = "./cert-manager"
  certmanager_aws_credentials = var.certmanager_aws_credentials
}

module "istio" {
  source = "./istio"
}

module "k8s-dashboard" {
  source = "./k8s-dashboard"
}

module "prometheus" {
  source = "./prometheus"
}

module "grafana" {
  source = "./grafana"
}
