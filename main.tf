terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

resource "tls_private_key" "frederik" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "frederik_tls_key" {
  sensitive_content    = tls_private_key.frederik.private_key_pem
  filename             = "${var.cert_directory}/frederik.key"
  file_permission      = "600"
  directory_permission = "700"
}

resource "tls_cert_request" "frederik" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.frederik.private_key_pem
  subject {
    common_name = "frederik"
  }
}

resource "kubernetes_certificate_signing_request" "frederik" {
  metadata {
    name = "frederik"
  }
  spec {
    request = tls_cert_request.frederik.cert_request_pem
  }
}

resource "local_file" "frederik_tls_crt" {
  content              = kubernetes_certificate_signing_request.frederik.certificate
  filename             = "${var.cert_directory}/frederik.crt"
  file_permission      = "644"
  directory_permission = "700"
}

resource "kubernetes_role" "developer" {
  metadata {
    name = "developer"
  }
  rule {
    api_groups = [""]
    verbs      = ["get", "list"]
    resources  = ["pods"]
  }
}

resource "kubernetes_role_binding" "frederik" {
  metadata {
    name = "role-binding-frederik"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "developer"
  }
  subject {
    kind      = "User"
    name      = "frederik"
    api_group = "rbac.authorization.k8s.io"
  }
}
