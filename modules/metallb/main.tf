
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

locals {
  namespace = "metallb"
}

resource "kubernetes_namespace" "pihole" {
  metadata {
    name = local.namespace
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = local.namespace
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.12.1"
  wait       = true
  atomic     = true
  values     = ["${file("${path.module}/values.yml")}"]
}
