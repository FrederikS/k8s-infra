
module "kubernetes" {
  source                      = "./modules/k8s"
  certmanager_aws_credentials = var.certmanager_aws_credentials
  github_token                = var.github_token
  keycloak_client_credentials = var.keycloak_client_credentials
}
