
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    github = {
      source = "integrations/github"
    }
  }
}

locals {
  name                 = "cicd"
  kubernetes_namespace = "default"
  kubernetes_api_url   = "https://k8s.fdk.codes:6443"
  github_repo_name     = "second-brain"
  cicd_sa_token_secret = "cicd-sa-token"
}

resource "kubernetes_role" "cicd" {
  metadata {
    name      = local.name
    namespace = local.kubernetes_namespace
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

# resource "kubernetes_service_account" "cicd" {
#   metadata {
#     name      = local.name
#     namespace = local.kubernetes_namespace
#   }

#   depends_on = [kubernetes_role.cicd]
# }

# FIXME: https://github.com/hashicorp/terraform-provider-kubernetes/issues/1724
resource "kubernetes_manifest" "cicd_service_account" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "ServiceAccount"
    "metadata" = {
      "name"      = local.name
      "namespace" = local.kubernetes_namespace
    }
  }
}


resource "kubernetes_secret" "cicd_sa_token" {
  metadata {
    name      = local.cicd_sa_token_secret
    namespace = local.kubernetes_namespace
    annotations = {
      "kubernetes.io/service-account.name" = local.name
    }
  }
  type = "kubernetes.io/service-account-token"

  depends_on = [
    kubernetes_manifest.cicd_service_account
  ]
}

resource "kubernetes_role_binding" "cicd" {
  metadata {
    name      = local.name
    namespace = local.kubernetes_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = local.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.name
    namespace = local.kubernetes_namespace
  }

  depends_on = [
    kubernetes_role.cicd,
    kubernetes_manifest.cicd_service_account
  ]
}

data "kubernetes_secret" "cicd_sa_token" {
  metadata {
    name      = local.cicd_sa_token_secret
    namespace = local.kubernetes_namespace
  }

  depends_on = [
    kubernetes_secret.cicd_sa_token
  ]
}

resource "github_actions_secret" "kubernetes-sa" {
  repository  = local.github_repo_name
  secret_name = "K8S_SA_SECRET"
  # Mimic a Kubernetes secret in YAML.
  # The GitHub action k8s-set-context only reads the `data` field anyway.
  plaintext_value = yamlencode({
    data = {
      "ca.crt"  = base64encode(data.kubernetes_secret.cicd_sa_token.data["ca.crt"])
      token     = base64encode(data.kubernetes_secret.cicd_sa_token.data.token)
      namespace = base64encode(data.kubernetes_secret.cicd_sa_token.data.namespace)
    }
  })

  depends_on = [
    kubernetes_secret.cicd_sa_token
  ]
}

resource "github_actions_secret" "kubernetes-api-url" {
  repository      = local.github_repo_name
  secret_name     = "K8S_API_URL"
  plaintext_value = local.kubernetes_api_url
}
