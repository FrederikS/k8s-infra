
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

resource "random_id" "kibana_username" {
  byte_length = 8
}

resource "random_password" "kibana_password" {
  length = 16
}

resource "random_password" "kibana_encryption_key" {
  length = 32
}

resource "kubernetes_secret" "kibana_credentials" {
  metadata {
    name      = "kibana-credentials"
    namespace = "logging"
  }

  data = {
    username      = random_id.kibana_username.id
    password      = random_password.kibana_password.result
    encryptionkey = random_password.kibana_encryption_key.result
  }
  depends_on = [random_id.kibana_username, random_password.kibana_password, random_password.kibana_encryption_key]
}

resource "helm_release" "kibana" {
  name             = "kibana"
  namespace        = "logging"
  create_namespace = true
  repository       = "https://helm.elastic.co"
  chart            = "kibana"
  version          = "7.17.1"
  values           = ["${file("${path.module}/values.yml")}"]
  timeout          = 500
  depends_on       = [kubernetes_secret.kibana_credentials]
}
