

```
📁 Your Git Repository Root
 │
 ├── 📁 kustomize-overlays/
 │    │
 │    ├── 📁 base/  ◄───────────────────────────┐ [1. REUSE CORE BLUEPRINT]
 │    │    ├── 📄 kustomization.yaml            │    Imports local resources
 │    │    ├── 📄 deployment.yaml (Replicas: 1) │    Clean, generic manifest
 │    │    └── 📄 service.yaml (Port: 80)       │    Clean, generic manifest
 │    │                                         │
 │    └── 📁 overlays/                          │
 │         │                                    │
 │         ├── 📁 development/                  │
 │         │    └── 📄 kustomization.yaml ──────┤ Links to ../../base
 │         │                                    │
 │         └── 📁 production/                   │
 │              ├── 📄 kustomization.yaml ──────┘ Links to ../../base + Defines Patches
 │              └── 📄 replica-patch.yaml ──────┐ [2. APPLY TARGETED CHANGES]
 │                                              │ Holds only the specific rows
 │                                              │ you want to mutate or overwrite
                                                │
                                                ▼
                                    ┌───────────────────────┐
                                    │ KUSTOMIZE PATCH ENGINE│
                                    └───────────┬───────────┘
                                                │
                                                ▼ [3. COMBINE & EMIT]
                                    Final Production Manifests
                                    (prod-web-app, Replicas: 5)
```
### How the "Patching" Engine Works (Line-by-Line)
Kustomize uses a process called Strategic Merge Patching. Instead of rewriting an entire file, you write a mini-snippet containing just enough metadata for Kustomize to match the target resource, followed by the exact lines you want to change.
1. The Base Files (kustomize-overlays/base/)
These files define your application's basic standard layout.

base/deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app       # <── The Engine matches on Group, Kind, and Name
spec:
  replicas: 1         # <── The row we want to change later
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```
base/kustomization.yaml
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml   # <── Tells Kustomize to load this file into memory
```
2. The Production Overlay Files (kustomize-overlays/overlays/production/)
Instead of copying the base deployment, we create two files: a small patch delta and the control configuration.
overlays/production/replica-patch.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app       # <── Tells the engine: "Find the deployment named web-app"
spec:
  replicas: 5         # <── Tells the engine: "Surgically overwrite the old '1' with '5'"
```
This file stitches the base blueprint and the patch delta together.
overlays/production/kustomization.yaml
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base        # <── 1. Pulls in the core files

patches:
  - path: replica-patch.yaml # <── 2. Runs the patch engine to modify the code

# Global modifiers applied to ALL resources automatically:
namePrefix: prod-     # Prepend "prod-" to all metadata names
commonLabels:
  env: production     # Injects this label into selectors and metadata blocks
```


