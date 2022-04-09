variable "credentials" {
  type = object({
    client_id     = string
    client_secret = string
  })
}
