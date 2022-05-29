
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

data "http" "cert_manager_crds" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/v${var.cert_manager_version}/cert-manager.crds.yaml"
}

locals {
  rawCertManagerCrds      = data.http.cert_manager_crds.body
  splitRawCertManagerCrds = split("SPLIT_DELIMITER", replace(local.rawCertManagerCrds, "/(?m:^---$)/", "SPLIT_DELIMITER"))
}

resource "kubernetes_manifest" "cert_manager_crds" {
  count    = length(local.splitRawCertManagerCrds) - 1
  manifest = yamldecode(element(local.splitRawCertManagerCrds, count.index + 1))
}
