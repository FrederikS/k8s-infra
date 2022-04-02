
locals {
  rawKcOperatorManifests      = file("${path.module}/keycloak_operator.yml")
  splitrawKcOperatorManifests = split("SPLIT_DELIMITER", replace(local.rawKcOperatorManifests, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  kcOperatorYamlManifests     = [for rawManifest in local.splitrawKcOperatorManifests : yamldecode(rawManifest)]
}

resource "kubernetes_manifest" "keycloak_namespace" {
  manifest = element(local.kcOperatorYamlManifests, 0)
}

resource "kubernetes_manifest" "keycloak_operator" {
  count      = length(local.kcOperatorYamlManifests) - 1
  manifest   = element(local.kcOperatorYamlManifests, count.index + 1)
  depends_on = [kubernetes_manifest.keycloak_namespace]
}
