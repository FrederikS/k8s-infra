
terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "3.7.0"
    }
  }
}

provider "keycloak" {
  client_id     = var.credentials.client_id
  client_secret = var.credentials.client_secret
  url           = "https://iam.fdk.codes"
}

locals {
  namespace = "keycloak"
}

data "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = "postgres"
  }
}

resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-creds"
    namespace = local.namespace
  }

  data = {
    user     = data.kubernetes_secret.postgres_credentials.data.keycloakUser
    password = data.kubernetes_secret.postgres_credentials.data.keycloakPassword
  }

  depends_on = [
    kubernetes_namespace.keycloak,
    data.kubernetes_secret.postgres_credentials
  ]
}

resource "random_id" "admin_username" {
  byte_length = 12
}

resource "random_password" "admin_password" {
  length = 16
}

resource "kubernetes_secret" "admin_credentials" {
  metadata {
    name      = "admin-creds"
    namespace = local.namespace
  }

  data = {
    user     = random_id.admin_username.id
    password = random_password.admin_password.result
  }

  depends_on = [
    random_id.admin_username,
    random_password.admin_password
  ]
}

resource "helm_release" "keycloak" {
  name             = "keycloak"
  namespace        = local.namespace
  create_namespace = true
  repository       = "https://codecentric.github.io/helm-charts"
  chart            = "keycloak"
  version          = "18.0.0"
  values           = ["${file("${path.module}/values.yml")}"]
  atomic           = true

  depends_on = [
    kubernetes_secret.admin_credentials,
    kubernetes_secret.db_credentials
  ]
}

resource "keycloak_realm" "fdk_codes" {
  realm        = "fdk-codes"
  display_name = "fdk.codes"
  ssl_required = "external"

  depends_on = [helm_release.keycloak]
}