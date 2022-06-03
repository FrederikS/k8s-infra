
variable "kubernetes_config_path" {
  type        = string
  description = "path to kubernetes config"
}

variable "kubernetes_context" {
  type        = string
  description = "kubernetes context to operate with"
}

variable "kubernetes_users" {
  type = map(object({
    group = string
  }))
  description = "users with cluster access"
  default = {
    frederik = {
      group = "devs"
    }
  }
}

variable "certmanager_aws_credentials" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
  sensitive = true
}

variable "github_owner" {
  type = string
}

variable "github_token" {
  type        = string
  description = "token to be used for the github provider"
  sensitive   = true
}

variable "keycloak_client_credentials" {
  type = object({
    client_id     = string
    client_secret = string
  })
  sensitive = true
}

variable "aws_region" {
  type = string
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
