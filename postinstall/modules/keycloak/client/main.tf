terraform {
  required_providers {
    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}

resource "keycloak_openid_client" "oidc_client" {
  realm_id              = var.realm_id
  client_id             = var.name
  name                  = var.name
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris = [
    "${var.url}/*"
  ]
}

resource "keycloak_role" "oidc_role" {
  realm_id = var.realm_id
  name     = var.role
}

output "client_id" {
  value     = keycloak_openid_client.oidc_client.client_id
  sensitive = true
}

output "client_secret" {
  value     = keycloak_openid_client.oidc_client.client_secret
  sensitive = true
}

output "role_id" {
  value     = keycloak_role.oidc_role.id
  sensitive = true
}
