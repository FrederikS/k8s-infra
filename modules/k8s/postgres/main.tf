
locals {
  # https://raw.githubusercontent.com/reactive-tech/kubegres/v1.15/kubegres.yaml
  rawKubegresManifests      = file("${path.module}/kubegres_operator.yml")
  splitRawKubegresManifests = split("SPLIT_DELIMITER", replace(local.rawKubegresManifests, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  kubegresYamlManifests     = [for rawManifest in local.splitRawKubegresManifests : yamldecode(rawManifest)]
}



resource "kubernetes_manifest" "kubegres_namespace" {
  manifest = element(local.kubegresYamlManifests, 0)
}

resource "kubernetes_manifest" "kubegres_operator" {
  count           = length(local.kubegresYamlManifests) - 1
  manifest        = element(local.kubegresYamlManifests, count.index + 1)
  depends_on      = [kubernetes_manifest.kubegres_namespace]
  computed_fields = ["metadata.creationTimestamp", "metadata.annotations", "metadata.labels"]
}

resource "random_password" "postgres_super_user_password" {
  length = 24
}

resource "random_password" "postgres_replication_user_password" {
  length = 24
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = "default"
  }

  data = {
    superUserPassword       = random_password.postgres_super_user_password.result
    replicationUserPassword = random_password.postgres_replication_user_password.result
  }
}

resource "kubernetes_manifest" "kubegres" {
  manifest        = yamldecode(file("${path.module}/kubegres.yml"))
  depends_on      = [kubernetes_manifest.kubegres_operator, kubernetes_secret.postgres_credentials]
  computed_fields = ["spec.customConfig", "spec.scheduler", "metadata.annotations", "metadata.labels"]
}

