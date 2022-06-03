
variable "kubernetes_config_path" {
  type        = string
  description = "path to kubernetes config"
}

variable "kubernetes_context" {
  type        = string
  description = "kubernetes context to operate with"
}

variable "keycloak_client_credentials" {
  type = object({
    client_id     = string
    client_secret = string
  })
  sensitive = true
}
