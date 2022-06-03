
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
}

resource "keycloak_realm" "fdk_codes" {
  realm        = "fdk-codes"
  display_name = "fdk.codes"
  ssl_required = "external"
}

resource "keycloak_openid_client" "oidc_client_notes_webapp" {
  realm_id              = keycloak_realm.fdk_codes.id
  client_id             = "notes-web-app"
  name                  = "notes-web-app"
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris = [
    "https://notes.fdk.codes/*"
  ]
  depends_on = [keycloak_realm.fdk_codes]
}

output "notes_webapp_client_id" {
  value     = keycloak_openid_client.oidc_client_notes_webapp.client_id
  sensitive = true
}

resource "kubernetes_secret" "client_credentials_notes_webapp" {
  metadata {
    name      = "client-credentials-notes-webapp"
    namespace = "keycloak"
  }

  data = {
    clientId     = keycloak_openid_client.oidc_client_notes_webapp.client_id
    clientSecret = keycloak_openid_client.oidc_client_notes_webapp.client_secret
  }

  depends_on = [keycloak_openid_client.oidc_client_notes_webapp]
}

# TODO fixme
resource "keycloak_user" "fdk" {
  realm_id       = keycloak_realm.fdk_codes.id
  email          = "fdk@fdk.codes"
  email_verified = true
  username       = "fdk"
  initial_password {
    value     = "1234"
    temporary = false
  }
  depends_on = [keycloak_realm.fdk_codes]
}

resource "keycloak_role" "notes_webapp_access" {
  realm_id = keycloak_realm.fdk_codes.id
  name     = "notes-webapp-access"
}

resource "keycloak_user_roles" "fdk" {
  realm_id = keycloak_realm.fdk_codes.id
  user_id  = keycloak_user.fdk.id

  role_ids = [
    keycloak_role.notes_webapp_access.id
  ]

  depends_on = [
    keycloak_user.fdk,
    keycloak_role.notes_webapp_access
  ]
}
