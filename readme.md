# 🚀 Local K8s Stack (KinD)

A streamlined guide for deploying a full-scale local Kubernetes environment. This setup includes Ingress, Monitoring, Logging, and GitOps.

---

### 📌 Table of Contents
1. [Cluster Setup](#1-cluster-setup)
2. [Ingress (Traefik)](#2-ingress-traefik)
3. [Monitoring (Prometheus & Grafana)](#3-monitoring-prometheus--grafana)
4. [Logging (Loki)](#4-logging-loki)
5. [GitOps (ArgoCD)](#5-gitops-argocd)

---

### 🛠 Prerequisites
Ensure you have the following CLI tools installed:
`docker`, `kubectl`, `helm`, `kind`.

---

### 1. Cluster Setup
Initialize the cluster and fix the Metrics Server for local use.

```bash
# Create cluster
kind create cluster --config kind-cluster.yaml

# Install Metrics Server
kubectl apply -f [https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)

# Patch Metrics Server
kubectl patch deployment metrics-server -n kube-system --type 'json' \
  -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Restart nodes (apply changes)
docker restart $(docker ps -aq --filter "name=kind")