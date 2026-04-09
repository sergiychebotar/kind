kind create cluster --config kind-cluster.yaml

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system --type 'json' \
  -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

kind delete cluster

helm install traefik traefik/traefik --set ports.web.nodePort=80 --set ports.websecure.nodePort=443 --set service.type=NodePort

helm install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack -f values-kube-prometheus-stack.yaml

helm install loki grafana/loki-stack \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=1Gi

kubectl create namespace argocd

kubectl apply --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd patch deployment argocd-server --type json \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["argocd-server"]}, {"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--insecure", "--staticassets", "/shared/app"]}]'

kubectl apply -f argocd-ingress.yaml

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
