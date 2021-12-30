
resource "helm_release" "istio-base" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istio-base"
  repository       = var.istio.repository
  chart            = "base"
  version          = var.istio.version

  dynamic "set" {
    for_each = var.istio.values
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "istiod" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istiod"
  repository       = var.istio.repository
  chart            = "istiod"
  version          = var.istio.version

  dynamic "set" {
    for_each = var.istio.values
    content {
      name  = set.key
      value = set.value
    }
  }
  depends_on = [helm_release.istio-base]
}

resource "helm_release" "istio_ingress" {
  namespace        = "istio-ingress"
  create_namespace = true
  name             = "istio-ingress"
  repository       = var.istio.repository
  chart            = "gateway"
  version          = var.istio.version
  depends_on       = [helm_release.istiod]
}
