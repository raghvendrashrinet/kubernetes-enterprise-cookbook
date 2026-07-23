# Module 05b: Dapr (Distributed Application Runtime)

## 📌 Overview

While Kubernetes manages container lifecycle, networking, and compute infrastructure, **Dapr (Distributed Application Runtime)** addresses application-level microservice challenges. Dapr acts as an **Event-Driven, Portable Application Runtime** that runs as a sidecar process alongside your application containers.

By abstracting common distributed system patterns behind standard HTTP and gRPC APIs, Dapr frees developers from embedding backend-specific SDKs (e.g., Redis, Kafka, AWS DynamoDB) directly into application code.

---
## 📐 Architecture & Flow

```text
+-----------------------------------------------------------------------------+
|                           Kubernetes Pod                                    |
|                                                                             |
|  +----------------------+   HTTP / gRPC    +------------------------------+ |
|  |   User App Container | <--------------> | Dapr Sidecar (daprd) Container| |
|  +----------------------+  localhost:3500  +--------------+---------------+ |
+-----------------------------------------------------------|-----------------+
                                                            |
                     +--------------------------------------+--------------------------------------+
                     |                                      |                                      |
                     v                                      v                                      v
     +------------------------------+       +------------------------------+       +------------------------------+
     |     State Store Component    |       |       Pub/Sub Component      |       |       Secret Store Component |
     |  (e.g., Redis, DynamoDB)     |       |     (e.g., Kafka, RabbitMQ)  |       | (e.g., Vault, K8s Secrets)   |
     +------------------------------+       +------------------------------+       +------------------------------+
```
## 🎯 Real-World Enterprise Use Cases

### 1. Multi-Cloud State Store Portability
* **Problem:** Applications hardcoded with cloud-specific SDKs (e.g., AWS DynamoDB or Azure Cosmos DB) require massive code refactoring when migrating or deploying to hybrid environments.
* **Dapr Solution:** Apps write to `http://localhost:3500/v1.0/state/statestore`. The backing store (Redis locally, AWS DynamoDB in AWS, Azure Cosmos DB in Azure) is swapped dynamically via Kubernetes `Component` Custom Resources (CRDs) without changing a single line of code.

### 2. Async Pub/Sub Event Decoupling
* **Problem:** Microservices communicating over synchronous REST APIs create tight coupling and cascading system failures during traffic spikes.
* **Dapr Solution:** Applications publish events to local Dapr endpoints (`http://localhost:3500/v1.0/publish/pubsub/orders`). Dapr handles message delivery via configured message brokers (Kafka, RabbitMQ, GCP Pub/Sub) with built-in retries, dead-letter queues, and CloudEvents formatting.

### 3. Distributed Tracing & Observability
* **Problem:** Instrumenting open-telemetry and distributed tracing across polyglot microservices (Node.js, Go, Python, Java) creates heavy maintenance overhead.
* **Dapr Solution:** Dapr sidecars handle W3C trace-context propagation and automatically stream telemetry to Zipkin, Jaeger, or Prometheus out of the box.

### 4. Resilient Service-to-Service Invocations
* **Problem:** Point-to-point microservice HTTP calls lack automatic retries, circuit breaking, and mutual TLS (mTLS).
* **Dapr Solution:** Services call target endpoints via Dapr (`http://localhost:3500/v1.0/invoke/order-service/method/pay`), automatically getting mTLS encryption, service discovery, and configurable resiliency policies.

---

## 🏗️ Dapr Architecture on Kubernetes

When deployed on Kubernetes, Dapr runs control plane pods to manage sidecar injection, configurations, state components, and mTLS certificates:

* `dapr-sidecar-injector`: Injects `daprd` sidecar containers into pods annotated with `dapr.io/enabled: "true"`.
* `dapr-operator`: Manages Dapr component definitions (`Component` CRDs) and K8s custom configurations.
* `dapr-placement`: Manages actor placement across instances.
* `dapr-sentry`: Acts as a Certificate Authority (CA) to issue mTLS certificates to Dapr sidecars.

---

## 🚀 Quickstart Guide: Hands-on Lab

### 1. Prerequisites
Ensure you have `kubectl` connected to your cluster and `helm` installed.

```bash
# Add Dapr Helm repository
helm repo add dapr [https://dapr.github.io/helm-charts/](https://dapr.github.io/helm-charts/)
helm repo update

# Install Dapr in dapr-system namespace

helm upgrade --install dapr dapr/dapr \
  --version 1.13.x \
  --namespace dapr-system \
  --create-namespace \
  --wait
```
Verify the control plane deployment:
```bash
kubectl get pods -n dapr-system
```
### 2. Define Infrastructure Components (CRDs)
##### A. State Store Component (statestore.yaml)
Configures a Redis instance as a key-value state store:
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: statestore
  namespace: default
spec:
  type: state.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis-master.default.svc.cluster.local:6379
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: redis-password
```
##### B. Pub/Sub Component (pubsub.yaml)
Configures an event broker for asynchronous messaging:
```yaml
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: order-pubsub
  namespace: default
spec:
  type: pubsub.redis
  version: v1
  metadata:
  - name: redisHost
    value: redis-master.default.svc.cluster.local:6379
  - name: redisPassword
    secretKeyRef:
      name: redis-secret
      key: redis-password
```
Apply components:
```
kubectl apply -f statestore.yaml
kubectl apply -f pubsub.yaml
```

### 3. Annotating Applications for Dapr Sidecar Injection
To enable Dapr for any application deployment, add annotations under .spec.template.metadata.annotations:
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: checkout-service
  template:
    metadata:
      labels:
        app: checkout-service
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "checkout-service"
        dapr.io/app-port: "8080"
    spec:
      containers:
      - name: user-app
        image: myregistry/checkout-service:v1.0.0
        ports:
        - containerPort: 8080
```
---

## ⚡ Dapr vs. Istio (Service Mesh)

| Feature | Istio Service Mesh | Dapr Application Runtime |
| :--- | :--- | :--- |
| **Primary Domain** | Network & Traffic Layer (L4/L7) | Application Architecture & Business Logic |
| **Primary Audience** | Platform Engineers / SREs | Developers & Application Architects |
| **Code Integration** | 100% Transparent (App is unaware) | Light API Calls (HTTP/gRPC to `localhost:3500`) |
| **Capabilities** | Traffic splitting, Canary releases, Ingress gateways | State management, Pub/Sub, Workflows, Secrets management |
| **Co-existence** | Handles ingress & service mesh security | Handles pub/sub, state, and distributed app patterns |

> 💡 **Best Practice:** In enterprise Kubernetes platforms, Istio and Dapr are commonly deployed together. Istio manages ingress traffic and platform mTLS, while Dapr manages application state and asynchronous event streams.


