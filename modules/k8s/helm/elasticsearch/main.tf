
terraform {
  required_providers {
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.1.0"
    }
  }
}

provider "elasticstack" {
  elasticsearch {
    username = "elastic"
    password = random_password.elastic_password.result
  }
}

resource "random_id" "elastic_username" {
  byte_length = 8
}

resource "random_password" "elastic_password" {
  length = 16
}

resource "kubernetes_secret" "elastic_credentials" {
  metadata {
    name      = "elastic-credentials"
    namespace = "logging"
  }

  data = {
    username = random_id.elastic_username.id
    password = random_password.elastic_password.result
  }
}

resource "helm_release" "elasticsearch" {
  name             = "elasticsearch"
  namespace        = "logging"
  create_namespace = true
  repository       = "https://helm.elastic.co"
  chart            = "elasticsearch"
  version          = "7.16.2"
  values           = ["${file("${path.module}/values.yml")}"]
  depends_on       = [kubernetes_secret.elastic_credentials]
}

resource "elasticstack_elasticsearch_index_template" "default_template" {
  name           = "default"
  index_patterns = ["*"]
  template {
    settings = jsonencode({
      number_of_replicas = 0
    })
  }

  depends_on = [helm_release.elasticsearch]
}
