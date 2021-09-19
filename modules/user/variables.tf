variable "name" {
  type        = string
  description = "name of the user"
}

variable "role" {
  type        = string
  description = "role for the user"
}

variable "cert_directory" {
  type        = string
  default     = "/tmp/certs"
  description = "path to directory for client user certs"
}