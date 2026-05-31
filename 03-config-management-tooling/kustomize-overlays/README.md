## 🟢 1. The Basic Definition of Kustomize
Kustomize is a native configuration management tool for Kubernetes that allows you to customize raw, template-free YAML files.

Unlike other tools that force you to mix programming logic (like variables, if/else loops, or placeholders) into your Kubernetes YAML files, Kustomize leaves your original files completely clean. 

### It works on a concept of Inheritance & Patching:

### 1. The Base: A folder containing your standard, clean Kubernetes manifests (like a Deployment or a Service) that represent the shared blueprint of your application.

### 2. The Overlay: A separate folder for a specific environment (like development or production). It imports the Base and contains instructions to cleanly modify or override specific lines (e.g., changing the replica count or adding environmental tags) before the code is sent to the cluster.
Overlays 
---------
Consists evironment specific values
 > Environment Name,
   Request /Limits,
   Labels.
   Replicas
```
┌──────────────────────────────┐
               │         THE BASE             │
               │   (Generic core manifests)   │
               │   e.g., replicas: 1          │
               └──────────────┬───────────────┘
                              │
                              │ (Inherited by)
                              ▼
        ┌───────────────────────────────────────────┐
        │               THE OVERLAYS                │
        │    (Environment-specific variations)      │
        └──────┬─────────────────────────────┬──────┘
               │                             │
               ▼                             ▼
  ┌─────────────────────────┐   ┌─────────────────────────┐
  │   DEVELOPMENT OVERLAY   │   │   PRODUCTION OVERLAY    │
  │   - Keeps replicas: 1   │   │   - Patches replicas: 5 │
  │   - Adds dev- prefix    │   │   - Adds prod- prefix   │
  └────────────┬────────────┘   └────────────┬────────────┘
               │                             │
               │ (kubectl apply -k)          │ (kubectl apply -k)
               ▼                             ▼
  ┌─────────────────────────┐   ┌─────────────────────────┐
  │  Generated Dev Cluster  │   │ Generated Prod Cluster  │
  │        Workloads        │   │        Workloads        │
  └─────────────────────────┘   └─────────────────────────┘
```
## 🗺️ Detailed Kustomize File & Patch Architecture
To understand how Kustomize works, you need to see both the directory layout and how the Patch Engine surgically modifies lines of code without using placeholders like {{ .Values }}.
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
