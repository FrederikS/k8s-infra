
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
    # grafana = {
    #   source  = "grafana/grafana"
    #   version = "1.17.0"
    # }
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.2.0"
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

module "roles" {
  source = "./modules/roles"
  providers = {
    kubernetes = kubernetes
  }
}

module "user" {
  source   = "./modules/user"
  for_each = var.kubernetes_users
  name     = each.key
  group    = each.value.group
  providers = {
    kubernetes = kubernetes
    tls        = tls
    local      = local
  }
}

module "serviceaccounts" {
  source = "./modules/serviceaccounts"
  providers = {
    kubernetes = kubernetes
    github     = github
  }
}

module "postgres" {
  source           = "./modules/postgres"
  kubegres_version = var.kubegres_version
  providers = {
    kubernetes = kubernetes
    random     = random
    http       = http
  }
}

module "cert-manager" {
  source                      = "./modules/cert-manager"
  cert_manager_version        = var.cert_manager_version
  certmanager_aws_credentials = var.certmanager_aws_credentials
  providers = {
    kubernetes = kubernetes
    helm       = helm
    aws        = aws
  }
}

module "istio" {
  source        = "./modules/istio"
  istio_version = var.istio_version
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "prometheus" {
  source = "./modules/prometheus"
  providers = {
    helm = helm
  }
}

module "grafana" {
  source = "./modules/grafana"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
}

module "elasticsearch" {
  source = "./modules/elasticsearch"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
}

module "fluentd" {
  source = "./modules/fluentd"
  providers = {
    helm = helm
  }
}

module "kibana" {
  source = "./modules/kibana"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
}

module "keycloak" {
  source = "./modules/keycloak"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
  depends_on = [
    module.postgres
  ]
}
