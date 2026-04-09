kind create cluster --config kind-cluster.yaml

kind delete cluster

helm install traefik traefik/traefik --set ports.web.nodePort=80 --set ports.websecure.nodePort=443 --set service.type=NodePort

helm install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack -f values-kube-prometheus-stack.yaml

helm install loki grafana/loki-stack \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=1Gi