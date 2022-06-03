
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
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

data "http" "cert_manager_crds" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/v${var.cert_manager_version}/cert-manager.crds.yaml"
}

data "http" "kubegres_operator" {
  url = "https://raw.githubusercontent.com/reactive-tech/kubegres/v${var.kubegres_version}/kubegres.yaml"
}

locals {
  rawCertManagerCrds        = data.http.cert_manager_crds.body
  splitRawCertManagerCrds   = split("SPLIT_DELIMITER", replace(local.rawCertManagerCrds, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  rawKubegresManifests      = data.http.kubegres_operator.body
  splitRawKubegresManifests = split("SPLIT_DELIMITER", replace(local.rawKubegresManifests, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  rawkubegresCrds           = element(local.splitRawKubegresManifests, 1)
  kubegresCrdsYaml          = yamldecode(local.rawkubegresCrds)
  fixedKubegresCrdsYaml     = { for k, v in local.kubegresCrdsYaml : k => v if k != "status" }
}

resource "kubernetes_manifest" "cert_manager_crds" {
  count    = length(local.splitRawCertManagerCrds) - 1
  manifest = yamldecode(element(local.splitRawCertManagerCrds, count.index + 1))
}

resource "kubernetes_manifest" "kubegres_crds" {
  manifest = local.fixedKubegresCrdsYaml
}

resource "helm_release" "istio-base" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = var.istio_version
  values           = ["${file("${path.module}/istio-base-values.yml")}"]
}
