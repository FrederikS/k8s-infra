
variable "kubernetes_config_path" {
  type        = string
  description = "path to kubernetes config"
}

variable "kubernetes_context" {
  type        = string
  description = "kubernetes context to operate with"
}

variable "istio" {
  type = object({
    repository = string
    version    = string
    values     = map(string)
  })
  default = {
    repository = "https://istio-release.storage.googleapis.com/charts"
    version    = "1.12.1"
    values = {
      "global.hub" = "docker.io/querycapistio"
    }
  }
}
