
locals {
  internalKeycloakUrl = "http://keycloak-http.keycloak.svc.cluster.local"
  keycloakUrl         = "https://iam.fdk.codes"
}

resource "helm_release" "istio-base" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istio-base"
  repository       = var.istio.repository
  chart            = "base"
  version          = var.istio.version
  values           = ["${file("${path.module}/istio-base-values.yml")}"]
}

resource "helm_release" "istiod" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istiod"
  repository       = var.istio.repository
  chart            = "istiod"
  version          = var.istio.version
  values           = ["${file("${path.module}/istiod-values.yml")}"]
  depends_on       = [helm_release.istio-base]
}

resource "helm_release" "istio_ingress" {
  namespace        = "istio-ingress"
  create_namespace = true
  name             = "istio-ingress"
  repository       = var.istio.repository
  chart            = "gateway"
  version          = var.istio.version
  values           = ["${file("${path.module}/gateway-values.yml")}"]
  depends_on       = [helm_release.istiod]
}

# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367
resource "kubernetes_manifest" "istio_gateway" {
  for_each   = fileset(path.module, "gateway/*")
  manifest   = yamldecode(file("${path.module}/${each.value}"))
  depends_on = [helm_release.istio-base]
}

data "kubernetes_secret" "client_credentials_notes_webapp" {
  metadata {
    name      = "client-credentials-notes-webapp"
    namespace = "keycloak"
  }
}

resource "random_id" "hmac_key" {
  byte_length = 32
}

resource "kubernetes_secret" "oauth_filter_credentials_notes_webapp" {
  metadata {
    name      = "oauth-filter-credentials-notes-webapp"
    namespace = "default"
  }
  data = {
    "token-secret.yaml" = "${templatefile("${path.module}/filter/envoy-token-secret.yml.tftpl", {
      "client_secret" = data.kubernetes_secret.client_credentials_notes_webapp.data.clientSecret
    })}"
    "hmac-secret.yaml" = "${templatefile("${path.module}/filter/envoy-hmac-secret.yml.tftpl", {
      "hmac_secret" = random_id.hmac_key.b64_std
    })}"
  }

  depends_on = [
    data.kubernetes_secret.client_credentials_notes_webapp,
    random_id.hmac_key
  ]
}

resource "kubernetes_manifest" "oauth_filter_notes_webapp" {
  manifest = yamldecode(templatefile(
    "${path.module}/filter/notes-webapp-oauth.yml.tftpl", {
      "client_id"      = data.kubernetes_secret.client_credentials_notes_webapp.data.clientId,
      "token_endpoint" = "${local.internalKeycloakUrl}/auth/realms/fdk-codes/protocol/openid-connect/token",
      "auth_endpoint"  = "${local.keycloakUrl}/auth/realms/fdk-codes/protocol/openid-connect/auth",
    }
  ))

  depends_on = [
    helm_release.istio_ingress,
    data.kubernetes_secret.client_credentials_notes_webapp,
    kubernetes_secret.oauth_filter_credentials_notes_webapp
  ]
}
