
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.23.0"
    }
  }
}

locals {
  name                 = "cicd"
  kubernetes_namespace = "default"
  kubernetes_api_url   = "https://k8s.fdk.codes:6443"
  github_owner         = "frederiks"
  github_repo_name     = "second-brain"
}

provider "github" {
  owner = local.github_owner
  token = var.github_token
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

resource "kubernetes_service_account" "cicd" {
  metadata {
    name      = local.name
    namespace = local.kubernetes_namespace
  }

  depends_on = [kubernetes_role.cicd]
}

data "kubernetes_secret" "cicd" {
  metadata {
    name      = kubernetes_service_account.cicd.default_secret_name
    namespace = local.kubernetes_namespace
  }

  depends_on = [kubernetes_service_account.cicd]
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
    kubernetes_service_account.cicd,
  ]
}

resource "github_actions_secret" "kubernetes-sa" {
  repository  = local.github_repo_name
  secret_name = "K8S_SA_SECRET"
  # Mimic a Kubernetes secret in YAML.
  # The GitHub action k8s-set-context only reads the `data` field anyway.
  plaintext_value = yamlencode({
    data = {
      "ca.crt"  = base64encode(data.kubernetes_secret.cicd.data["ca.crt"])
      token     = base64encode(data.kubernetes_secret.cicd.data.token)
      namespace = base64encode(data.kubernetes_secret.cicd.data.namespace)
    }
  })
}

resource "github_actions_secret" "kubernetes-api-url" {
  repository      = local.github_repo_name
  secret_name     = "K8S_API_URL"
  plaintext_value = local.kubernetes_api_url
}
