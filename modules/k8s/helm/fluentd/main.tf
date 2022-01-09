
# resource "kubernetes_config_map" "fluentd" {
#   metadata {
#     name      = "elasticsearch-output"
#     namespace = "logging"
#   }
#   data = {
#     "fluentd.conf" = "${file("${path.module}/fluentd.conf")}"
#   }
# }

resource "helm_release" "fluentd" {
  name             = "fluentd"
  namespace        = "logging"
  create_namespace = true
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluentd"
  version          = "0.3.4"
  values           = ["${file("${path.module}/values.yml")}"]

  # set {
  #   name  = "image.repository"
  #   value = "fluent/fluentd-kubernetes-daemonset"
  # }

  set {
    name  = "image.tag"
    value = "v1-debian-elasticsearch-arm64"
  }
}

# resource "helm_release" "fluentd" {
#   name             = "fluentd"
#   namespace        = "logging"
#   create_namespace = true
#   repository       = "https://charts.bitnami.com/bitnami"
#   chart            = "fluentd"
#   version          = "4.5.1"

#   set {
#     name  = "image.repository"
#     value = "fluent/fluentd"
#   }

#   set {
#     name  = "image.tag"
#     value = "v1.14.4-debian-arm64-1.0"
#   }

#   set {
#     name  = "aggregator.configMap"
#     value = "elasticsearch-output"
#   }

#   set {
#     name  = "aggregator.extraEnv[0].name"
#     value = "ELASTICSEARCH_HOST"
#   }

#   set {
#     name  = "aggregator.extraEnv[0].value"
#     value = var.elasticsearch_host
#   }

#   set {
#     name  = "aggregator.extraEnv[1].name"
#     value = "ELASTICSEARCH_PORT"
#   }

#   set {
#     name  = "aggregator.extraEnv[1].value"
#     value = var.elasticsearch_port
#     type  = "string"
#   }
# }
