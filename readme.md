🚀 Local K8s Development Stack with KinD
This repository provides a streamlined guide and set of scripts to deploy a complete local Kubernetes development environment using KinD (Kubernetes in Docker).

The stack includes: Traefik (Ingress), Kube-Prometheus-Stack (Monitoring), Loki (Logging), and ArgoCD (GitOps).

🛠 Prerequisites
Ensure you have the following installed:

Docker

kubectl

Helm 3

KinD

🏗 Step 1: Create KinD Cluster
We initialize the cluster with a custom configuration (to map ports 80/443) and set up the Metrics Server.

Bash
# 1. Create the cluster
kind create cluster --config kind-cluster.yaml

# 2. Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 3. Patch Metrics Server for KinD (bypass TLS verification)
kubectl patch deployment metrics-server -n kube-system --type 'json' \
  -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# 4. Refresh KinD nodes to apply changes (optional but recommended)
docker restart $(docker ps -aq --filter "name=kind")
🚦 Step 2: Ingress Controller (Traefik)
Traefik acts as the entry point for all external traffic.

Bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik \
  --set ports.web.nodePort=80 \
  --set ports.websecure.nodePort=443 \
  --set service.type=NodePort
📊 Step 3: Monitoring (Kube-Prometheus-Stack)
Full observability suite including Prometheus and Grafana.

Bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  -f values-kube-prometheus-stack.yaml

# Retrieve Grafana admin password (Username: admin)
kubectl get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
📝 Step 4: Logging (Grafana Loki)
Lightweight log aggregation for your cluster.

Bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki grafana/loki-stack \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=1Gi
🐙 Step 5: GitOps (ArgoCD)
Automated application delivery.

Bash
# 1. Create namespace and install
kubectl create namespace argocd
kubectl apply --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Patch for insecure mode (local development only)
kubectl -n argocd patch deployment argocd-server --type json \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["argocd-server"]},
       {"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--insecure", "--staticassets", "/shared/app"]}]'

# 3. Apply Ingress for ArgoCD
kubectl apply -f argocd-ingress.yaml

# 4. Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
🔍 Cheat Sheet
Delete cluster: kind delete cluster

Check all Pods: kubectl get pods -A

Watch logs: kubectl logs -f <pod-name>

Resource cleanup: docker system prune -a (Caution: removes all unused Docker data)

Note on WSL2/Windows: Ensure your kind-cluster.yaml includes extraPortMappings for ports 80 and 443. To access your services, add entries like 127.0.0.1 argocd.local to your Windows hosts file.