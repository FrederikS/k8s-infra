
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

resource "helm_release" "istio-base" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istio-base"
  repository       = var.istio.repository
  chart            = "base"
  version          = var.istio.version

  dynamic "set" {
    for_each = var.istio.values
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "istiod" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istiod"
  repository       = var.istio.repository
  chart            = "istiod"
  version          = var.istio.version

  dynamic "set" {
    for_each = var.istio.values
    content {
      name  = set.key
      value = set.value
    }
  }
}
