
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

module "cicd" {
  source = "./modules/cicd"
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

module "metallb" {
  source = "./modules/metallb"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "istio" {
  source        = "./modules/istio"
  istio_version = var.istio_version
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  depends_on = [
    module.metallb
  ]
}

module "cert-manager" {
  source                       = "./modules/cert-manager"
  cert_manager_version         = var.cert_manager_version
  certmanager_aws_credentials  = var.certmanager_aws_credentials
  aws_region                   = var.aws_region
  aws_dns_zone_id              = var.aws_dns_zone_id
  aws_iam_role_dns_manager_arn = var.aws_iam_role_dns_manager_arn
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  depends_on = [
    module.istio
  ]
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
  depends_on = [
    module.cert-manager,
    module.prometheus
  ]
}

module "elasticsearch" {
  source = "./modules/elasticsearch"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
  depends_on = [
    module.cert-manager
  ]
}

module "fluentd" {
  source = "./modules/fluentd"
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  depends_on = [
    module.elasticsearch
  ]
}

module "kibana" {
  source = "./modules/kibana"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
  depends_on = [
    module.elasticsearch
  ]
}

module "keycloak" {
  source = "./modules/keycloak"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
  depends_on = [
    module.cert-manager,
    module.postgres
  ]
}

module "pihole" {
  source = "./modules/pi-hole"
  providers = {
    kubernetes = kubernetes
    helm       = helm
    random     = random
  }
  depends_on = [
    module.metallb
  ]
}
