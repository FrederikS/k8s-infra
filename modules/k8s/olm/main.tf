
locals {
  # https://github.com/operator-framework/operator-lifecycle-manager/blob/v0.20.0/deploy/upstream/quickstart/crds.yaml
  rawOlmCrds           = file("${path.module}/olm_crds.yml")
  splitRawOlmCrds      = split("SPLIT_DELIMITER", replace(local.rawOlmCrds, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  olmCrdsYamlManifests = [for rawCrd in local.splitRawOlmCrds : yamldecode(rawCrd)]
  # https://github.com/operator-framework/operator-lifecycle-manager/blob/v0.20.0/deploy/upstream/quickstart/olm.yaml
  rawOlmOperatorManifests      = file("${path.module}/olm_operator.yml")
  splitrawOlmOperatorManifests = split("SPLIT_DELIMITER", replace(local.rawOlmOperatorManifests, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  olmOperatorYamlManifests     = [for rawManifest in local.splitrawOlmOperatorManifests : yamldecode(rawManifest)]
}

resource "kubernetes_manifest" "olm_crds" {
  count           = length(local.olmCrdsYamlManifests)
  manifest        = element(local.olmCrdsYamlManifests, count.index)
  computed_fields = ["metadata.creationTimestamp", "metadata.annotations", "metadata.labels"]
}

resource "kubernetes_manifest" "olm_namespace" {
  manifest = element(local.olmOperatorYamlManifests, 0)
}

resource "kubernetes_manifest" "olm_operator" {
  count      = length(local.olmOperatorYamlManifests) - 1
  manifest   = element(local.olmOperatorYamlManifests, count.index + 1)
  depends_on = [kubernetes_manifest.olm_namespace]
}

