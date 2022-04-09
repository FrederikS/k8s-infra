
variable "certmanager_aws_credentials" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
}

variable "github_token" {
  type        = string
  description = "token to be used for the github provider"
}

variable "keycloak_client_credentials" {
  type = object({
    client_id     = string
    client_secret = string
  })
}
