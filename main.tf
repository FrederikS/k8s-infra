
module "kubernetes" {
  source                      = "./modules/k8s"
  certmanager_aws_credentials = var.certmanager_aws_credentials
  github_token                = var.github_token
}
