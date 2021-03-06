
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

resource "helm_release" "istiod" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = var.istio_version
  values           = ["${file("${path.module}/istiod-values.yml")}"]
  atomic           = true
}

resource "helm_release" "istio_ingress" {
  namespace        = "istio-ingress"
  create_namespace = true
  name             = "istio-ingress"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = var.istio_version
  values           = ["${file("${path.module}/gateway-values.yml")}"]
  atomic = true
  depends_on       = [helm_release.istiod]
}

# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367
resource "kubernetes_manifest" "istio_gateway" {
  for_each   = fileset(path.module, "gateway/*")
  manifest   = yamldecode(file("${path.module}/${each.value}"))
  depends_on = [helm_release.istio_ingress]
}
