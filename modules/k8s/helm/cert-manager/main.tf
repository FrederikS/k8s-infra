
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_policy" "route53_list_change" {
  name   = "Route53ListChangeResourceRecordSetsFdkCodes"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/${var.aws_dns_zone_id}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "dns_manager" {
  name                = "dns-manager"
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.aws_dns_manager_role_account_arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  managed_policy_arns = [aws_iam_policy.route53_list_change.arn]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.7.1"

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
      "region" : var.aws_region,
      "zone_id" : var.aws_dns_zone_id,
      "role" : aws_iam_role.dns_manager.arn
      "access_key_id" : var.certmanager_aws_credentials.access_key_id
    }
  ))
  depends_on = [aws_iam_role.dns_manager]
}

resource "kubernetes_manifest" "cert" {
  manifest = yamldecode(file("${path.module}/cert.yml"))
}
