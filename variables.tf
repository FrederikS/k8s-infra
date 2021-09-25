variable "kubernetes_config_path" {
  type        = string
  default     = "/etc/rancher/k3s/k3s.yaml"
  description = "path to kubernetes config"
}

variable "kubernetes_context" {
  type        = string
  default     = "default"
  description = "kubernetes context to operate with"
}

variable "cert_directory" {
  type        = string
  default     = "/var/lib/rancher/k3s/server/tls"
  description = "path to directory for client user certs"
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
