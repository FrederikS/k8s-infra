
variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "aws_dns_zone_id" {
  type    = string
  default = "Z02131432BPRD17CWC45P"
}

variable "aws_dns_manager_role_account_arn" {
  type    = string
  default = "arn:aws:iam::172099792315:user/Administrator"
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
