
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    random = {
      source = "hashicorp/random"
    }
    github = {
      source = "integrations/github"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
    aws = {
      source = "hashicorp/aws"
    }
    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}

module "helm" {
  source                      = "./helm"
  certmanager_aws_credentials = var.certmanager_aws_credentials
  depends_on                  = [module.postgres]
  providers = {
    kubernetes = kubernetes
    helm       = helm
    aws        = aws
    random     = random
    keycloak   = keycloak
  }
}

module "roles" {
  source = "./roles"
  providers = {
    kubernetes = kubernetes
  }
}

module "user" {
  source   = "./user"
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
  source = "./serviceaccounts"
  providers = {
    kubernetes = kubernetes
    github     = github
  }
}

module "postgres" {
  source = "./postgres"
  providers = {
    kubernetes = kubernetes
    random     = random
  }
}

# module "keycloak" {
#   source     = "./keycloak"
#   depends_on = [module.postgres]
# }
