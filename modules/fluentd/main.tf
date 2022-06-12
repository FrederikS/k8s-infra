
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

resource "helm_release" "fluentd" {
  name             = "fluentd"
  namespace        = "logging"
  create_namespace = true
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluentd"
  version          = "0.3.5"
  values           = ["${file("${path.module}/values.yml")}"]

  set {
    name  = "image.tag"
    value = "v1-debian-elasticsearch7-arm64"
  }
}

resource "kubernetes_manifest" "fluentd_cert" {
  manifest        = yamldecode(file("${path.module}/fluentd_cert.yml"))
  computed_fields = ["spec.isCA"]
}
