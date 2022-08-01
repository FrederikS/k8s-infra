
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

module "notes_oidc_client" {
  source   = "./client"
  realm_id = keycloak_realm.fdk_codes.id
  name     = "notes-web-app"
  url      = "https://notes.fdk.codes"
  role     = "notes-webapp-access"

  providers = {
    keycloak = keycloak
  }
  depends_on = [
    keycloak_realm.fdk_codes
  ]
}

resource "kubernetes_secret" "client_credentials_notes_webapp" {
  metadata {
    name      = "client-credentials-notes-webapp"
    namespace = "keycloak"
  }

  data = {
    clientId     = module.notes_oidc_client.client_id
    clientSecret = module.notes_oidc_client.client_secret
  }

  depends_on = [module.notes_oidc_client]
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

resource "keycloak_user_roles" "fdk" {
  realm_id = keycloak_realm.fdk_codes.id
  user_id  = keycloak_user.fdk.id

  role_ids = [
    module.notes_oidc_client.role_id
  ]

  depends_on = [
    keycloak_user.fdk,
    module.notes_oidc_client
  ]
}
