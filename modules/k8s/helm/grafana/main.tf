
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "1.17.0"
    }
  }
}

provider "grafana" {
  url = "https://grafana.fdk.codes/"
  auth = format("%s:%s",
    random_id.grafana_username.id,
    random_password.grafana_password.result
  )
}

resource "random_id" "grafana_username" {
  byte_length = 8
}

resource "random_password" "grafana_password" {
  length = 16
}

resource "kubernetes_secret" "grafana_credentials" {
  metadata {
    name      = "grafana-credentials"
    namespace = "monitoring"
  }

  data = {
    username = random_id.grafana_username.id
    password = random_password.grafana_password.result
  }
}

resource "helm_release" "grafana" {
  name             = "grafana"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = "6.23.2"
  set {
    name  = "admin.existingSecret"
    value = "grafana-credentials"
  }

  set {
    name  = "admin.userKey"
    value = "username"
  }

  set {
    name  = "admin.passwordKey"
    value = "password"
  }

  depends_on = [kubernetes_secret.grafana_credentials]
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
  depends_on  = [helm_release.grafana]
}
