
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
