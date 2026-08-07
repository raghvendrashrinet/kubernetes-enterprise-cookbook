
## Scenario: High-Scale E-Commerce Microservice Architecture
Imagine an enterprise running a core Payment Gateway API deployed across multiple cloud regions and environments using ArgoCD / Flux and GitOps.
```
1. Repository Directory Structure
Plaintext
payment-service/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── patch-replicas.yaml
    └── production/
        ├── kustomization.yaml
        ├── patch-resources.yaml
        └── patch-hpa.yaml
```
#### 2. The Shared Base Layer (/base)
The base layer defines standard Kubernetes manifests without custom logic or template variables ({{ .Values }}).

- `base/kustomization.yaml`

```YAML
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

# Applies to all resources generated from this base
commonLabels:
  app.kubernetes.io/name: payment-service
  app.kubernetes.io/managed-by: argocd
base/deployment.yaml
```
```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
        - name: payment-api
          image: myregistry.azurecr.io/payment-api:v2.1.0
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: payment-config
```
#### 3. Production Overlay Layer (/overlays/production)
In production, you need:

- Higher replica counts and strict CPU/Memory resource constraints.

- Injected production ConfigMaps generated directly from files.

- Injected Datadog APM tracing sidecars or custom security annotations without modifying the base manifest.

** `overlays/production/kustomization.yaml`

```YAML
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: payment-production

# Inherit base configuration
resources:
  - ../../base

# 1. Image Tag Management (Update container image per environment release)
images:
  - name: myregistry.azurecr.io/payment-api
    newTag: v2.4.1-prod

# 2. ConfigMap Generation with Hash Suffixing (Forces pod restart on config changes)
configMapGenerator:
  - name: payment-config
    literals:
      - LOG_LEVEL=WARN
      - DB_MAX_CONNECTIONS=50
      - ENABLE_FEATURE_FLAG_X=true

# 3. Environment Patches
patches:
  # Strategic Merge Patch for resource limits
  - path: patch-resources.yaml
  # Inline JSON 6902 Patch for adding node selectors
  - target:
      kind: Deployment
      name: payment-service
    patch: |-
      - op: add
        path: /spec/template/spec/nodeSelector
        value:
          workload: high-security
```

** `overlays/production/patch-resources.yaml`

```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  replicas: 10
  template:
    spec:
      containers:
        - name: payment-api
          resources:
            requests:
              cpu: "1000m"
              memory: "1Gi"
            limits:
              cpu: "2000m"
              memory: "2Gi"
```
