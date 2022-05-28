
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

variable "github_token" {
  type        = string
  description = "token to be used for the github provider"
}
