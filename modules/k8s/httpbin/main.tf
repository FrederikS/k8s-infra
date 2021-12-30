
resource "kubernetes_manifest" "httpbin_service_account" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "ServiceAccount"
    "metadata" = {
      "name"      = "httpbin"
      "namespace" = "default"
    }
  }
}

resource "kubernetes_manifest" "httpbin_deployment" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata" = {
      "name"      = "httpbin"
      "namespace" = "default"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app"     = "httpbin"
          "version" = "v1"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app"     = "httpbin"
            "version" = "v1"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image"           = "docker.io/suika/httpbin"
              "imagePullPolicy" = "IfNotPresent"
              "name"            = "httpbin"
              "ports" = [
                {
                  "containerPort" = 80
                },
              ]
            },
          ]
          "serviceAccountName" = "httpbin"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "httpbin_service" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "labels" = {
        "app"     = "httpbin"
        "service" = "httpbin"
      }
      "name"      = "httpbin"
      "namespace" = "default"
    }
    "spec" = {
      "ports" = [
        {
          "name"       = "http"
          "port"       = 8000
          "targetPort" = 80
        },
      ]
      "selector" = {
        "app" = "httpbin"
      }
    }
  }
}

resource "kubernetes_manifest" "httpbin_gateway" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1alpha3"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "httpbin-gateway"
      "namespace" = "default"
    }
    "spec" = {
      "selector" = {
        "istio" = "ingress"
      }
      "servers" = [
        {
          "hosts" = [
            "httpbin.fdk.codes",
          ]
          "port" = {
            "name"     = "http"
            "number"   = 80
            "protocol" = "HTTP"
          }
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "httpbin_virtual_service" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1alpha3"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "httpbin"
      "namespace" = "default"
    }
    "spec" = {
      "gateways" = [
        "httpbin-gateway",
      ]
      "hosts" = [
        "httpbin.fdk.codes",
      ]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/status"
              }
            },
            {
              "uri" = {
                "prefix" = "/delay"
              }
            },
          ]
          "route" = [
            {
              "destination" = {
                "host" = "httpbin"
                "port" = {
                  "number" = 8000
                }
              }
            },
          ]
        },
      ]
    }
  }
}
