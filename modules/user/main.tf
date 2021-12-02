resource "tls_private_key" "user" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "user_tls_key" {
  sensitive_content    = tls_private_key.user.private_key_pem
  filename             = "${var.cert_directory}/${var.name}.key"
  file_permission      = "600"
  directory_permission = "700"
}

resource "tls_cert_request" "user" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.user.private_key_pem
  subject {
    common_name = var.name
  }
}

resource "kubernetes_certificate_signing_request_v1" "user" {
  metadata {
    name = var.name
  }
  spec {
    signer_name = "kubernetes.io/kube-apiserver-client"
    usages      = ["client auth"]
    request     = tls_cert_request.user.cert_request_pem
  }
  auto_approve = true
}

resource "local_file" "user_tls_crt" {
  content              = kubernetes_certificate_signing_request_v1.user.certificate
  filename             = "${var.cert_directory}/${var.name}.crt"
  file_permission      = "644"
  directory_permission = "700"
}

resource "kubernetes_role_binding" "user" {
  metadata {
    name = "role-binding-${var.name}"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = var.role
  }
  subject {
    kind      = "User"
    name      = var.name
    api_group = "rbac.authorization.k8s.io"
  }
}
