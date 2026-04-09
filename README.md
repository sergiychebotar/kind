# 🚀 Local K8s Development Stack (KinD)

A professional, automated setup for a local Kubernetes environment. This stack provides a production-like experience using KinD, Traefik, Prometheus/Grafana, Loki, and ArgoCD.

---

### 📌 Table of Contents
1. [Cluster Infrastructure](#1-cluster-infrastructure)
2. [Ingress Controller (Traefik)](#2-ingress-controller-traefik)
3. [Monitoring Stack (Prometheus & Grafana)](#3-monitoring-stack-prometheus--grafana)
4. [Logging Stack (Loki)](#4-logging-stack-loki)
5. [GitOps (ArgoCD)](#5-gitops-argocd)

---

### 🛠 Prerequisites
Before you start, ensure you have these tools installed:
docker, kubectl, helm, kind.

---

### 1. Cluster Infrastructure
We initialize the cluster and configure the Metrics Server for resource monitoring.

# Create the cluster with custom config
kind create cluster --config kind-cluster.yaml

# Install Metrics Server
kubectl apply -f [https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)

# Patch Metrics Server to allow insecure TLS (required for KinD)
kubectl patch deployment metrics-server -n kube-system --type 'json' \
  -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Restart KinD containers to apply changes
docker restart $(docker ps -aq --filter "name=kind")

---

### 2. Ingress Controller (Traefik)
Traefik is used as the entry point to handle HTTP/HTTPS traffic via NodePorts.

helm repo add traefik [https://traefik.github.io/charts](https://traefik.github.io/charts)
helm repo update

helm install traefik traefik/traefik \
  --set ports.web.nodePort=80 \
  --set ports.websecure.nodePort=443 \
  --set service.type=NodePort

---

### 3. Monitoring Stack (Prometheus & Grafana)
Deploy the kube-prometheus-stack via OCI registry for full observability.

helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo update

helm install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  -f values-kube-prometheus-stack.yaml

---

### 4. Logging Stack (Loki)
Lightweight log aggregation using the Loki-stack.

helm repo add grafana [https://grafana.github.io/helm-charts](https://grafana.github.io/helm-charts)
helm repo update

helm install loki grafana/loki-stack \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=1Gi

---

### 5. GitOps (ArgoCD)
Setup ArgoCD for declarative GitOps workflows.

# Create namespace and install ArgoCD
kubectl create namespace argocd
kubectl apply --server-side -f [https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)

# Patch for Insecure (HTTP) and Static Assets access
kubectl -n argocd patch deployment argocd-server --type json \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["argocd-server"]},
       {"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--insecure", "--staticassets", "/shared/app"]}]'

# Apply Ingress rules for ArgoCD
kubectl apply -f argocd-ingress.yaml

---

### 🔐 Access Credentials

Use these commands to retrieve admin credentials:

| Service | Username | Command to get Password |
| :--- | :--- | :--- |
| Grafana | admin | kubectl get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" \| base64 -d |
| ArgoCD | admin | kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d |

---

### 💡 Maintenance & Cleanup
* Accessing Ingress: Map your local domains (e.g., argocd.local) to 127.0.0.1 in your OS hosts file.
* Remove Cluster: To wipe everything, simply run: kind delete cluster