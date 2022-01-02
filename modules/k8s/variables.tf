variable "kubernetes_config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "path to kubernetes config"
}

variable "kubernetes_context" {
  type        = string
  default     = "pi-admin"
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
}
