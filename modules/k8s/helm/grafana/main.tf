
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "1.17.0"
    }
  }
}

provider "grafana" {
  url = "http://grafana.fdk.codes/"
  auth = format("%s:%s",
    data.kubernetes_secret.grafana.data["admin-user"],
    data.kubernetes_secret.grafana.data["admin-password"]
  )
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "istio-system"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.20.3"
}

data "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "istio-system"
  }
  depends_on = [helm_release.grafana]
}

resource "grafana_data_source" "prometheus" {
  type       = "prometheus"
  name       = "prometheus"
  url        = "http://prometheus-server"
  is_default = true

  json_data {
    http_method = "POST"
  }
  depends_on = [helm_release.grafana]
}

resource "grafana_dashboard" "dashboard" {
  for_each    = fileset(path.module, "dashboard/*")
  config_json = file("${path.module}/${each.value}")
}
