
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
  }
}

locals {
  namespace = "pihole"
}

resource "random_password" "admin_password" {
  length = 16
}

resource "kubernetes_namespace" "pihole" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret" "admin_credentials" {
  metadata {
    name      = "admin-credentials"
    namespace = local.namespace
  }

  data = {
    password = random_password.admin_password.result
  }

  depends_on = [
    kubernetes_namespace.pihole,
    random_password.admin_password
  ]
}

resource "helm_release" "pihole" {
  name       = "pihole"
  namespace  = local.namespace
  repository = "https://mojo2600.github.io/pihole-kubernetes/"
  chart      = "pihole"
  version    = "2.5.8"
  wait       = true
  atomic     = true
  values     = ["${file("${path.module}/values.yml")}"]
}
