
variable "aws_region" {
  type = string
}

variable "aws_dns_zone_id" {
  type = string
}

variable "aws_iam_role_dns_manager_arn" {
  type = string
}

variable "certmanager_aws_credentials" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
}

variable "cert_manager_version" {
  type = string
}
