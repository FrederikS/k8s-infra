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

variable "cert_directory" {
  type        = string
  default     = "/tmp/certs"
  description = "path to directory for client user certs"
}