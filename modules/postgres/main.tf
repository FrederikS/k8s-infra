
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}

data "http" "kubegres_operator" {
  url = "https://raw.githubusercontent.com/reactive-tech/kubegres/v${var.kubegres_version}/kubegres.yaml"
}

locals {
  rawKubegresManifests      = data.http.kubegres_operator.body
  splitRawKubegresManifests = split("SPLIT_DELIMITER", replace(local.rawKubegresManifests, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  kubegresYamlManifests     = [for rawManifest in local.splitRawKubegresManifests : yamldecode(rawManifest)]
  fixedkubegresYamlManifests = [for manifest in local.kubegresYamlManifests : merge(manifest, {
    metadata = { for k, v in {
      labels      = try(manifest.metadata.labels, null)
      annotations = try(manifest.metadata.annotations, null)
      name        = try(manifest.metadata.name, null)
      namespace   = try(manifest.metadata.namespace, null)
    } : k => v if v != null }
  })]
}

resource "kubernetes_manifest" "kubegres_namespace" {
  manifest = element(local.fixedkubegresYamlManifests, 0)
}

resource "kubernetes_manifest" "kubegres_operator" {
  count           = length(local.fixedkubegresYamlManifests) - 2
  manifest        = element(local.fixedkubegresYamlManifests, count.index + 2)
  depends_on      = [kubernetes_manifest.kubegres_namespace]
  computed_fields = ["metadata.creationTimestamp", "metadata.annotations", "metadata.labels"]
}

resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "postgres"
  }
}

resource "random_password" "postgres_super_user_password" {
  length = 24
}

resource "random_password" "postgres_replication_user_password" {
  length = 24
}

resource "random_string" "postgres_keycloak_user" {
  length  = 12
  upper   = false
  special = false
  number  = false
}

resource "random_password" "postgres_keycloak_password" {
  length = 24
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = "postgres"
  }

  data = {
    superUserPassword       = random_password.postgres_super_user_password.result
    replicationUserPassword = random_password.postgres_replication_user_password.result
    keycloakUser            = random_string.postgres_keycloak_user.id
    keycloakPassword        = random_password.postgres_keycloak_password.result
  }

  depends_on = [kubernetes_manifest.kubegres_namespace]
}

resource "kubernetes_manifest" "postgres_config" {
  manifest   = yamldecode(file("${path.module}/postgres_config.yml"))
  depends_on = [kubernetes_manifest.kubegres_namespace]
}

resource "kubernetes_manifest" "kubegres" {
  manifest = yamldecode(file("${path.module}/kubegres.yml"))
  depends_on = [
    kubernetes_manifest.kubegres_operator,
    kubernetes_secret.postgres_credentials,
    kubernetes_manifest.postgres_config
  ]
  computed_fields = ["spec.customConfig", "spec.scheduler", "metadata.annotations", "metadata.labels"]
}

