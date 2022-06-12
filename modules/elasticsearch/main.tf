
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
  namespace = "logging"
}

resource "random_id" "elastic_username" {
  byte_length = 8
}

resource "random_password" "elastic_password" {
  length = 16
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret" "elastic_credentials" {
  metadata {
    name      = "elastic-credentials"
    namespace = "logging"
  }

  data = {
    username = random_id.elastic_username.id
    password = random_password.elastic_password.result
  }
  depends_on = [kubernetes_namespace.logging]
}

resource "helm_release" "elasticsearch" {
  name             = "elasticsearch"
  namespace        = "logging"
  create_namespace = true
  repository       = "https://helm.elastic.co"
  chart            = "elasticsearch"
  version          = "7.17.1"
  values           = ["${file("${path.module}/values.yml")}"]
  timeout          = 500
  atomic = true
  depends_on       = [kubernetes_secret.elastic_credentials]
}

resource "kubernetes_manifest" "es_cert" {
  manifest        = yamldecode(file("${path.module}/elasticsearch_cert.yml"))
  computed_fields = ["spec.isCA"]
}
