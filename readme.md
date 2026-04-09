----------Quick and easy install Kube-Prometheus-stack, Grafana-Loki, ArgoCD, traefik as ingress-----------------------------------------
----------------------------into local cluster created with Kind--------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
1. Kind part

kind create cluster --config kind-cluster.yaml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type 'json' \
  -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
docker stop $(docker ps -q --filter "name=kind")
docker start $(docker ps -aq --filter "name=kind")
kind delete cluster
-------------------------------------------------------------------------------------------------------------------------------------
2. traefik part

helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik --set ports.web.nodePort=80 --set ports.websecure.nodePort=443 --set service.type=NodePort
-------------------------------------------------------------------------------------------------------------------------------------
3. Kube-Prometheus-stack part

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack -f values-kube-prometheus-stack.yaml
kubectl --namespace default get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
-------------------------------------------------------------------------------------------------------------------------------------
4. Grafana - Loki part

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki grafana/loki-stack \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=1Gi
-------------------------------------------------------------------------------------------------------------------------------------
5. ArgoCD part

kubectl create namespace argocd
kubectl apply --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd patch deployment argocd-server --type json \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["argocd-server"]}, {"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--insecure", "--staticassets", "/shared/app"]}]'
kubectl apply -f argocd-ingress.yaml
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
-------------------------------------------------------------------------------------------------------------------------------------