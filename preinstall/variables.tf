
variable "kubernetes_config_path" {
  type        = string
  description = "path to kubernetes config"
}

variable "kubernetes_context" {
  type        = string
  description = "kubernetes context to operate with"
}

variable "cert_manager_version" {
  type = string
}

variable "istio_version" {
  type = string
}

variable "kubegres_version" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_dns_zone_id" {
  type = string
}

variable "aws_dns_manager_role_account_arn" {
  type = string
}
