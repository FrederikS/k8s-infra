variable "name" {
  type        = string
  description = "name of the user"
}

variable "group" {
  type        = string
  description = "group for the user"
}

variable "cert_directory" {
  type        = string
  default     = "./certs"
  description = "path to directory for client user certs"
}