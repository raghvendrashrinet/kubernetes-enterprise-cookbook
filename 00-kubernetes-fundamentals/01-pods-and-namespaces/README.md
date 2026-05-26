# Concept 01: Workload Isolation via Pods and Namespaces

## 💡 Key Architectural Concepts
* **Namespaces:** Virtual logical partitions inside a physical Kubernetes cluster. Essential for separating multi-tenant environments (`dev`, `staging`, `prod`) or dividing resources between engineering business units.
* **Pods:** The smallest atomic deployable unit in Kubernetes. A pod encapsulates one or more application containers, sharing the exact same network namespace, storage volumes, and runtime lifecycle context.

## 🚀 How to Execute & Verify
1. Apply the manifest to provision both the namespace and the container pod:
   ```bash
   kubectl apply -f pod-isolation.yaml

Attempt to list the pods in the default namespace (it will show nothing!):
```bash
kubectl get pods
```

Target the custom namespace to verify successful initialization and status tracking:
```bash
kubectl get pods -n team-alpha -o wide
