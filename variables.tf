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

variable "users" {
  type = map(object({
    role = string
  }))
  description = "users with cluster access"
  default = {
    frederik = {
      role = "developer"
    }
  }
}
