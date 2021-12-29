
resource "kubernetes_role" "developer" {
  metadata {
    name = "developer"
  }
  rule {
    api_groups = [""]
    verbs      = ["get", "list"]
    resources  = ["pods"]
  }
}

resource "kubernetes_role_binding" "developer" {
  metadata {
    name = "role-binding-developer"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "developer"
  }
  subject {
    kind      = "Group"
    name      = "devs"
    api_group = "rbac.authorization.k8s.io"
  }
}
