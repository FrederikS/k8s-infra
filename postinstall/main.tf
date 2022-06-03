
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
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "3.7.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

provider "keycloak" {
  client_id     = var.keycloak_client_credentials.client_id
  client_secret = var.keycloak_client_credentials.client_secret
  url           = "https://iam.fdk.codes"
}

module "keycloak" {
  source = "./modules/keycloak"
  providers = {
    kubernetes = kubernetes
    keycloak   = keycloak
  }
}

module "istio" {
  source                          = "./modules/istio"
  keycloak_notes_webapp_client_id = module.keycloak.notes_webapp_client_id
  providers = {
    kubernetes = kubernetes
    random     = random
  }
  depends_on = [
    module.keycloak
  ]
}

