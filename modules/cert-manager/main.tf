
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_secret" "aws_cert_manager_credientials" {
  metadata {
    name      = "cert-manager-aws-credentials"
    namespace = "istio-ingress"
  }

  data = {
    access_key_id     = var.certmanager_aws_credentials.access_key_id
    secret_access_key = var.certmanager_aws_credentials.secret_access_key
  }
}

resource "kubernetes_manifest" "issuer" {
  manifest = yamldecode(templatefile(
    "${path.module}/issuer.yml.tftpl", {
      "region"        = var.aws_region
      "zone_id"       = var.aws_dns_zone_id
      "role"          = var.aws_iam_role_dns_manager_arn
      "access_key_id" = var.certmanager_aws_credentials.access_key_id
    }
  ))
}

resource "kubernetes_manifest" "cert" {
  manifest = yamldecode(file("${path.module}/cert.yml"))
}

resource "kubernetes_manifest" "selfsigned_issuer" {
  manifest = yamldecode(file("${path.module}/selfsigned_issuer.yml"))
}

resource "kubernetes_manifest" "es_root_ca_cert" {
  manifest   = yamldecode(file("${path.module}/logging/root_ca_cert.yml"))
  depends_on = [kubernetes_manifest.selfsigned_issuer]
}

resource "kubernetes_manifest" "es_root_ca_issuer" {
  manifest   = yamldecode(file("${path.module}/logging/root_ca_issuer.yml"))
  depends_on = [kubernetes_manifest.es_root_ca_cert]
}

resource "kubernetes_manifest" "es_cert" {
  manifest        = yamldecode(file("${path.module}/logging/elasticsearch_cert.yml"))
  computed_fields = ["spec.isCA"]
  depends_on      = [kubernetes_manifest.es_root_ca_issuer]
}

resource "kubernetes_manifest" "kibana_cert" {
  manifest        = yamldecode(file("${path.module}/logging/kibana_cert.yml"))
  computed_fields = ["spec.isCA"]
  depends_on      = [kubernetes_manifest.es_root_ca_issuer]
}

resource "kubernetes_manifest" "fluentd_cert" {
  manifest        = yamldecode(file("${path.module}/logging/fluentd_cert.yml"))
  computed_fields = ["spec.isCA"]
  depends_on      = [kubernetes_manifest.es_root_ca_issuer]
}
