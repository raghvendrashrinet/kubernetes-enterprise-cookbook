# kubernetes-enterprise-cookbook
```
aks-production-kb/
├── README.md
├── 00-kubernetes-fundamentals/          # (Core objects: Pods, Deployments, Services, Configs, Jobs)
├── 01-advanced-pod-scheduling/          # (Affinity, Taints, Sidecars, InitContainers)
├── 02-stateful-and-storage/             # (PV, PVC, Dynamic StorageClasses)
├── 03-config-management-tooling/       # (Helm, Kustomize)
│
├── 04-enterprise-networking-edge/      # 🌐 RESTRUCTURED: Production Traffic Routing
│   ├── 01-cert-manager-ssl-rotation/
│   ├── 02-blue-green-canary-routing/
│   └── 03-gateway-api-aks-routing/      # 🔥 ADDED: Modern replacement for standard Ingress
│
├── 05-service-mesh-istio/               # (mTLS, Traffic Shifting)
│
├── 06-autoscaling-hpa-keda/             # (HPA, KEDA Event-Driven Scaling)
│
├── 07-cluster-security-governance/      # 🔒 ADDED: Critical Job Requirement
│   ├── 01-azure-workload-identity/      # 🔥 ADDED: Passwordless Cloud Authentication
│   ├── 02-kyverno-admission-controller/ # 🔥 ADDED: Policy Enforcement / Guardrails
│   └── 03-network-policies-cilium/      # 🔥 ADDED: Network Firewalls & eBPF
│
├── 08-gitops-continuous-delivery/       # 🚀 ADDED: Standard Enterprise CI/CD
│   └── argocd-fleet-management/         # 🔥 ADDED: Declarative GitOps engine
│
├── 09-enterprise-observability/         # (Fluentbit, Prometheus, Grafana)
├── 10-real-world-capstone-app/          # (Comprehensive E-Commerce Architecture)
└── 99-troubleshooting-handbook/          # (SRE Field Triaging Matrix)

```
