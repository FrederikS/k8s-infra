
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
    github = {
      source  = "integrations/github"
      version = "4.23.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "3.7.0"
    }
    # grafana = {
    #   source  = "grafana/grafana"
    #   version = "1.17.0"
    # }
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubernetes_config_path
    config_context = var.kubernetes_context
  }
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

provider "aws" {
  region = var.aws_region
}

provider "keycloak" {
  client_id     = var.keycloak_client_credentials.client_id
  client_secret = var.keycloak_client_credentials.client_secret
  url           = "https://iam.fdk.codes"
}

module "kubernetes" {
  source                      = "./modules/k8s"
  certmanager_aws_credentials = var.certmanager_aws_credentials
  github_token                = var.github_token
  providers = {
    kubernetes = kubernetes
    random     = random
    github     = github
    tls        = tls
    local      = local
    helm       = helm
    aws        = aws
    keycloak   = keycloak
  }
}
