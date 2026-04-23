resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Prometheus stack (включає Grafana!)
resource "helm_release" "kube_prometheus" {
  name       = "kube-prometheus"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  values = [
    file("${path.module}/values/prometheus.yaml")
  ]
}

# Loki
resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"

  values = [
    file("${path.module}/values/loki.yaml")
  ]
}