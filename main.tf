
module "kubernetes" {
  source                      = "./modules/k8s"
  certmanager_aws_credentials = var.certmanager_aws_credentials
}
