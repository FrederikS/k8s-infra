
resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = "15.0.2"
  values           = ["${file("${path.module}/values.yml")}"]
}
