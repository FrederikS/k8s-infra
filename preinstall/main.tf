
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubernetes_config_path
    config_context = var.kubernetes_context
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

output "aws_iam_role_dns_manager_arn" {
  value = aws_iam_role.dns_manager.arn
}

data "http" "cert_manager_crds" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/v${var.cert_manager_version}/cert-manager.crds.yaml"
}

data "http" "kubegres_operator" {
  url = "https://raw.githubusercontent.com/reactive-tech/kubegres/v${var.kubegres_version}/kubegres.yaml"
}

locals {
  rawCertManagerCrds        = data.http.cert_manager_crds.body
  splitRawCertManagerCrds   = split("SPLIT_DELIMITER", replace(local.rawCertManagerCrds, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  rawKubegresManifests      = data.http.kubegres_operator.body
  splitRawKubegresManifests = split("SPLIT_DELIMITER", replace(local.rawKubegresManifests, "/(?m:^---$)/", "SPLIT_DELIMITER"))
  rawkubegresCrds           = element(local.splitRawKubegresManifests, 1)
  kubegresCrdsYaml          = yamldecode(local.rawkubegresCrds)
  fixedKubegresCrdsYaml     = { for k, v in local.kubegresCrdsYaml : k => v if k != "status" }
}

resource "kubernetes_manifest" "cert_manager_crds" {
  count    = length(local.splitRawCertManagerCrds) - 1
  manifest = yamldecode(element(local.splitRawCertManagerCrds, count.index + 1))
}

resource "kubernetes_manifest" "kubegres_crds" {
  manifest        = local.fixedKubegresCrdsYaml
  computed_fields = ["metadata.creationTimestamp", "metadata.annotations", "metadata.labels"]
}

resource "helm_release" "istio-base" {
  namespace        = "istio-system"
  create_namespace = true
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = var.istio_version
  values           = ["${file("${path.module}/istio-base-values.yml")}"]
}
