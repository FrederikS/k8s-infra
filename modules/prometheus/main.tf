
terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = "15.5.3"
  values           = ["${file("${path.module}/values.yml")}"]
}
