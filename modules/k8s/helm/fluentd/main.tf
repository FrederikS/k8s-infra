
resource "kubernetes_config_map" "fluentd_elasticsearch" {
  metadata {
    name      = "fluentd-elasticsearch"
    namespace = "logging"
  }
  data = {
    "index_template.json" = "${file("${path.module}/index-template.json")}"
  }
}

resource "helm_release" "fluentd" {
  name             = "fluentd"
  namespace        = "logging"
  create_namespace = true
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluentd"
  version          = "0.3.4"
  values           = ["${file("${path.module}/values.yml")}"]

  set {
    name  = "image.tag"
    value = "v1-debian-elasticsearch-arm64"
  }
  depends_on = [kubernetes_config_map.fluentd_elasticsearch]
}
