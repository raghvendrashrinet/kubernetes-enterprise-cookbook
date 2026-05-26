#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting enterprise cookbook directory initialization..."

# Array containing all the nested path structures
declare -a directories=(
    "00-kubernetes-fundamentals/01-pods-and-namespaces"
    "00-kubernetes-fundamentals/02-deployments-and-probes"
    "00-kubernetes-fundamentals/03-services-and-networking"
    "00-kubernetes-fundamentals/04-configmaps-and-secrets"
    "00-kubernetes-fundamentals/05-jobs-and-cronjobs"
    "01-advanced-pod-scheduling/01-node-selectors-affinity"
    "01-advanced-pod-scheduling/02-taints-and-tolerations"
    "01-advanced-pod-scheduling/03-multi-container-design"
    "02-stateful-and-storage/01-static-storage-pv-pvc"
    "02-stateful-and-storage/02-dynamic-storageclass"
    "03-config-management-tooling/kustomize-overlays"
    "03-config-management-tooling/helm-charts"
    "04-enterprise-networking-edge/01-cert-manager-ssl-rotation"
    "04-enterprise-networking-edge/02-blue-green-canary-routing"
    "04-enterprise-networking-edge/03-gateway-api-aks-routing"
    "05-service-mesh-istio/mutual-tls-security"
    "05-service-mesh-istio/traffic-shifting"
    "06-autoscaling-hpa-keda/hpa-resource-metrics"
    "06-autoscaling-hpa-keda/keda-event-driven-scaling"
    "07-cluster-security-governance/01-azure-workload-identity"
    "07-cluster-security-governance/02-kyverno-admission-controller"
    "07-cluster-security-governance/03-network-policies-cilium"
    "08-gitops-continuous-delivery/argocd-fleet-management"
    "09-enterprise-observability"
    "10-real-world-capstone-app/e-commerce-architecture"
    "99-troubleshooting-handbook"
)

# Loop through each path, create it, and add a placeholder .gitkeep file
for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        touch "$dir/.gitkeep"
        echo "📂 Created: $dir/ with .gitkeep"
    else
        echo "⚠️  Skipping (Already Exists): $dir"
    fi
done

echo "✅ All directories successfully structured and tracked!"
