
locals {
  namespace        = "keycloak"
  postgres_db      = "keycloak"
  postgres_address = "postgres.postgres.svc.cluster.local"
  postgres_port    = "5432"
}

resource "kubernetes_manifest" "keycloak_crd" {
  for_each = fileset(path.module, "crds/*")
  manifest = yamldecode(file("${path.module}/${each.value}"))
}

resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_manifest" "keycloak_role" {
  manifest   = yamldecode(file("${path.module}/role.yaml"))
  depends_on = [kubernetes_namespace.keycloak]
}

resource "kubernetes_manifest" "keycloak_service_account" {
  manifest   = yamldecode(file("${path.module}/service_account.yaml"))
  depends_on = [kubernetes_namespace.keycloak]
}

resource "kubernetes_manifest" "keycloak_role_binding" {
  manifest = yamldecode(file("${path.module}/role_binding.yaml"))
  depends_on = [
    kubernetes_manifest.keycloak_role,
    kubernetes_manifest.keycloak_service_account
  ]
}

resource "kubernetes_manifest" "keycloak_operator" {
  manifest   = yamldecode(file("${path.module}/operator.yaml"))
  depends_on = [kubernetes_manifest.keycloak_service_account]
}

data "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = "postgres"
  }

}

resource "kubernetes_secret" "keycloak_db" {
  metadata {
    name      = "keycloak-db-secret"
    namespace = local.namespace
  }

  data = {
    POSTGRES_DATABASE         = local.postgres_db
    POSTGRES_EXTERNAL_ADDRESS = local.postgres_address
    POSTGRES_EXTERNAL_PORT    = local.postgres_port
    POSTGRES_USERNAME         = data.kubernetes_secret.postgres_credentials.data.keycloakUser
    POSTGRES_PASSWORD         = data.kubernetes_secret.postgres_credentials.data.keycloakPassword
  }

  depends_on = [data.kubernetes_secret.postgres_credentials]
}

resource "kubernetes_manifest" "keycloak" {
  manifest = yamldecode(file("${path.module}/keycloak.yaml"))
  depends_on = [
    kubernetes_manifest.keycloak_crd,
    kubernetes_manifest.keycloak_operator,
    kubernetes_secret.keycloak_db
  ]
}

resource "kubernetes_manifest" "fdk_codes_realm" {
  manifest   = yamldecode(file("${path.module}/keycloak_realm_fdk_codes.yaml"))
  depends_on = [kubernetes_manifest.keycloak]
}

resource "kubernetes_manifest" "fdk_codes_notes_client" {
  manifest   = yamldecode(file("${path.module}/keycloak_client_fdk_codes_notes.yaml"))
  depends_on = [kubernetes_manifest.keycloak]
}

resource "random_password" "fdk_user_password" {
  length = 16
}

resource "kubernetes_manifest" "fdk_codes_user" {
  manifest = yamldecode(templatefile(
    "${path.module}/keycloak_user_fdk_codes.yaml.tftpl", {
      "fdk_user_password" = random_password.fdk_user_password.result
    }
  ))

  depends_on = [
    kubernetes_manifest.keycloak,
    random_password.fdk_user_password
  ]
}
