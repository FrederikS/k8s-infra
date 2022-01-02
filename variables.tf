
variable "certmanager_aws_credentials" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
}
