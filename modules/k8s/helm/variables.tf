
variable "kubernetes_config_path" {
  type        = string
  description = "path to kubernetes config"
}

variable "kubernetes_context" {
  type        = string
  description = "kubernetes context to operate with"
}

variable "certmanager_aws_credentials" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
}
