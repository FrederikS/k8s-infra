
resource "helm_release" "kubernetes_dashboard" {
  namespace  = "kube-system"
  name       = "kubernetes-dashboard"
  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  version    = "5.0.5"
}

resource "kubernetes_service_account" "admin_user" {
  metadata {
    name      = "admin-user"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "admin_user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "admin-user"
    namespace = "kube-system"
  }
}

resource "kubernetes_manifest" "k8s_dashboard_gateway" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1alpha3"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "kubernetes-dashboard-gateway"
      "namespace" = "kube-system"
    }
    "spec" = {
      "selector" = {
        "istio" = "ingress"
      }
      "servers" = [
        {
          "hosts" = [
            "k8s-dashboard.fdk.codes",
          ]
          "port" = {
            "name"     = "https"
            "number"   = 443
            "protocol" = "HTTPS"
          }
          "tls" = {
            "mode" = "PASSTHROUGH"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "k8s_dashboard_virtual_service" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1alpha3"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "kubernetes-dashboard"
      "namespace" = "kube-system"
    }
    "spec" = {
      "gateways" = [
        "kubernetes-dashboard-gateway",
      ]
      "hosts" = [
        "k8s-dashboard.fdk.codes",
      ]
      "tls" = [
        {
          "match" = [
            {
              "port" = 443
              "sniHosts" = [
                "k8s-dashboard.fdk.codes",
              ]
            },
          ]
          "route" = [
            {
              "destination" = {
                "host" = "kubernetes-dashboard"
                "port" = {
                  "number" = 443
                }
              }
            },
          ]
        },
      ]
    }
  }
}
