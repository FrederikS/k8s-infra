
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}

module "cert-manager" {
  source                      = "./cert-manager"
  certmanager_aws_credentials = var.certmanager_aws_credentials
  providers = {
    kubernetes = kubernetes
    helm       = helm
    aws        = aws
  }
}

module "istio" {
  source = "./istio"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
}

module "prometheus" {
  source = "./prometheus"
  providers = {
    helm = helm
  }
}

module "grafana" {
  source = "./grafana"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
}

module "elasticsearch" {
  source = "./elasticsearch"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
}

module "fluentd" {
  source = "./fluentd"
  providers = {
    helm = helm
  }
}

module "kibana" {
  source = "./kibana"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
}

module "keycloak" {
  source = "./keycloak"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
    keycloak   = keycloak
  }
}
