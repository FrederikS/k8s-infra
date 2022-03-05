
resource "helm_release" "kibana" {
  name             = "kibana"
  namespace        = "logging"
  create_namespace = true
  repository       = "https://helm.elastic.co"
  chart            = "kibana"
  version          = "7.16.3"
  values           = ["${file("${path.module}/values.yml")}"]
  timeout          = 500
}
