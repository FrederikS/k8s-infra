
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

locals {
  internalKeycloakUrl = "http://keycloak-http.keycloak.svc.cluster.local"
  keycloakUrl         = "https://iam.fdk.codes"
}

resource "helm_release" "istiod" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = var.istio_version
  values           = ["${file("${path.module}/istiod-values.yml")}"]
}

resource "helm_release" "istio_ingress" {
  namespace        = "istio-ingress"
  create_namespace = true
  name             = "istio-ingress"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = var.istio_version
  values           = ["${file("${path.module}/gateway-values.yml")}"]
  depends_on       = [helm_release.istiod]
}

# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367
resource "kubernetes_manifest" "istio_gateway" {
  for_each = fileset(path.module, "gateway/*")
  manifest = yamldecode(file("${path.module}/${each.value}"))
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
    "${path.module}/filter/envoy-oauth-filter.yml.tftpl", {
      "name"           = "notes-webapp-oauth-filter",
      "app_name"       = "second-brain",
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

resource "kubernetes_manifest" "authn_notes_webapp" {
  manifest = yamldecode(templatefile(
    "${path.module}/auth/notes-webapp-authn.yml.tftpl", {
      "issuer"   = "https://iam.fdk.codes/auth/realms/fdk-codes"
      "jwks_uri" = "${local.internalKeycloakUrl}/auth/realms/fdk-codes/protocol/openid-connect/certs"
    }
  ))
}

resource "kubernetes_manifest" "authz_notes_webapp" {
  manifest = yamldecode(templatefile(
    "${path.module}/auth/notes-webapp-authz.yml.tftpl", {
      "role" = "notes-webapp-access"
    }
  ))
}
