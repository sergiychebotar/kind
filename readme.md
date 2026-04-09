🚀 Local K8s Stack (KinD)A streamlined guide for deploying a full-scale local Kubernetes environment. This setup includes Ingress, Monitoring, Logging, and GitOps.📌 Table of ContentsCluster SetupIngress (Traefik)Monitoring (Prometheus & Grafana)Logging (Loki)GitOps (ArgoCD)🛠 PrerequisitesEnsure you have the following CLI tools installed:docker, kubectl, helm, kind.1. Cluster SetupInitialize the cluster and fix the Metrics Server for local use.Bash# Create cluster
kind create cluster --config kind-cluster.yaml

# Install & Patch Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type 'json' \
  -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Restart nodes (apply changes)
docker restart $(docker ps -aq --filter "name=kind")
2. Ingress (Traefik)Set up Traefik to handle incoming traffic via NodePorts.Bashhelm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
  --set ports.web.nodePort=80 \
  --set ports.websecure.nodePort=443 \
  --set service.type=NodePort
3. Monitoring (Prometheus & Grafana)Deploy the observability stack using the OCI registry.Bashhelm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  -f values-kube-prometheus-stack.yaml
4. Logging (Loki)Add log aggregation with persistence enabled.Bashhelm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=1Gi
5. GitOps (ArgoCD)Install ArgoCD and configure it for local Ingress access.Bashkubectl create namespace argocd
kubectl apply --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Patch for insecure (HTTP) access
kubectl -n argocd patch deployment argocd-server --type json \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["argocd-server"]},
       {"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--insecure", "--staticassets", "/shared/app"]}]'

kubectl apply -f argocd-ingress.yaml
🔐 Access CredentialsServiceUsernameCommand to get PasswordGrafanaadminkubectl get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -dArgoCDadminkubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d