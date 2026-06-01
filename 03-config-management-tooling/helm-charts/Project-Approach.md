### Real World Project Approach
> The Golden Rule of Helm: You must first have working, static, raw Kubernetes YAML manifests that you have manually tested and verified on your cluster. Only when your raw YAML works do you begin converting it into a dynamic Helm chart.

 #### 🗺️ Step 1: The Blueprinting & Planning Phase
Before writing a single line of a chart, you create a mapping matrix. You look at your working static manifests and ask: "What parts of this file will change depending on who is using it or where it is being deployed?"
Let's plan for our order-processor application:

# Kubernetes Components: Static vs Dynamic

| The Kubernetes Component | What stays Static (Hardcoded)?         | What becomes Dynamic (Placeholder)?       |
|---------------------------|----------------------------------------|-------------------------------------------|
| Deployment Metadata       | API Version, Kind, Strategy Type       | Name, Namespace, Labels                   |
| Pod Specification         | Container structures, Port layouts     | Replica Count, Docker Image Tag           |
| Resource Allocations      | The syntax wrapper (`resources:`)      | Exact CPU and Memory limits/requests      |

#### 🛠️ Step 2: Setting Up the Workspace
Helm comes with a built-in scaffolding tool that creates the required skeleton directory structure for you.
```
# This creates a folder named 'order-processor' with all boilerplate files
helm create order-processor
```
##### Cleaning out the noise:
The default scaffolding creates a lot of extra files (like ingress, service accounts, and testing notes) that can be confusing when you are learning. Let's wipe the slate clean so we can build it step-by-step
```
# Clean out the default generated templates so we can write our own
rm -rf order-processor/templates/*
```
Your directory structure will now look clean and manageable:
```
📁 order-processor/
 ├── 📄 Chart.yaml          <── The metadata package index
 ├── 📄 values.yaml         <── The central parameter control panel
 └── 📁 templates/          <── Empty room where our dynamic blueprints go
```
#### ✍️ Step 3: Writing the Chart (The 3-Step Code Pattern)
Now we translate our planning into files, working from the global settings down to the specific templates.
###### 1. Register the Package (Chart.yaml)
Open Chart.yaml and define the identity of this package. This stays clean and descriptive.
```
apiVersion: v2
name: order-processor
description: An enterprise-grade parameterized chart for order processing
type: application
version: 1.0.0
appVersion: "1.0.0"
```
##### 2. Define the Controls (values.yaml)
Next, declare your variables. These are the default values that will be injected into your templates if no one overrides them.
```
# The Control Panel Variables
replicaCount: 2

image:
  repository: nginx
  tag: "1.25.0"
  pullPolicy: IfNotPresent
```
##### 3. Build the Template (templates/deployment.yaml)
Now, take your raw, working Kubernetes deployment manifest and surgically replace the hardcoded values with your placeholder tags.
```
apiVersion: apps/v1
kind: Deployment
metadata:
  # Using built-in Helm release tracking for the name
  name: {{ .Release.Name }}-deployment
  namespace: team-alpha
spec:
  replicas: {{ .Values.replicaCount }} # Pulls from values.yaml -> replicaCount
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: engine
        # Blends repository and tag string keys together dynamically
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: 80
```
#### 🔬 Step 4: The Sanity Check Verification
Once you have written these three files, you must verify that the rendering engine works perfectly before deploying it to your cluster.
```
helm template test-release order-processor/
```
What to check in your terminal output:
Look closely at the generated YAML text that prints out:
- Verify that name: reads test-release-deployment.
- Verify that replicas: is the integer 2.
- Verify that image: has cleanly combined your inputs into nginx:1.25.0.

### Deployement
##### 🏢 The Enterprise Deployment Pattern
We create separate, isolated override files for each environment. When running our deployment pipelines, we instruct Helm to prioritize the override file over the default values.
```
📦 Core Chart Folder (order-processor/)
    ├── 📄 values.yaml (Generic, low-resource defaults)
    └── 📁 templates/
         ▼
 🚀 CI/CD Pipeline Deployment Trigger
    ├── For Dev:  helm install --values env-dev.yaml
    └── For Prod: helm install --values env-prod.yaml
```
##### Step 1: Create Your Environment Override Files
Create these two separate files right outside your core order-processor/ chart directory (e.g., in your root helm-charts/ folder) to handle your target environments.

File 1: The Development Profile (env-dev.yaml)
Optimized for cost savings, running single instances with debug configurations.
```
replicaCount: 1  # Low footprint for testing

resources:
  requests:
    cpu: "50m"
    memory: "64Mi"
  limits:
    cpu: "100m"
    memory: "128Mi"

appEnv:
  DB_HOST: "dev-database.internal.net"
  LOG_LEVEL: "debug"
```
File 2: The Production Profile (env-prod.yaml)
Optimized for high availability, scale, and performance limits.
```
replicaCount: 5  # High availability scale

resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "1024Mi"

appEnv:
  DB_HOST: "prod-secure-cluster.database.azure.com"
  LOG_LEVEL: "error"
```
##### 🚀 Step 2: Execute the Deployments Live
Now we pass these profiles into our terminal using the -f (file) or --values flag.
🟢 1. Deploying the Development Stack
```
helm upgrade --install order-api-dev ./order-processor \
  --namespace team-alpha-dev \
  --create-namespace \
  -f env-dev.yaml
```
💡 Note: We use upgrade --install. This is an industry-standard best practice command. It checks if the release exists: if it doesn't, it installs it; if it does, it upgrades it cleanly.

🔴 2. Deploying the Production Stack
```
helm upgrade --install order-api-prod ./order-processor \
  --namespace team-alpha-prod \
  --create-namespace \
  -f env-prod.yaml
```
#### Step 3: Verifying the Live Running State
```
# 1. Check your active Helm releases across the namespaces
helm list --namespace team-alpha-dev
helm list --namespace team-alpha-prod

# 2. Verify Pod Scaling differences
kubectl get pods --namespace team-alpha-dev
# (You will see exactly 1 active pod running)

kubectl get pods --namespace team-alpha-prod
# (You will see exactly 5 active pods running in parallel)

# 3. Verify Container Environment Variable Isolation
kubectl exec -it deployment/order-api-prod-deploy -n team-alpha-prod -- env | grep DB_HOST
# Output: DB_HOST=prod-secure-cluster.database.azure.com
```
### 🗺️ Visualizing the Rolling Update & Rollback Engine
When you execute an upgrade or rollback, Helm communicates with the Kubernetes Control Plane to orchestrate a safe transition of containers:
```
🔄 CURRENT STATE (Revision 1)     🚀 RUNNING THE UPGRADE          🎯 TARGET STATE (Revision 2)
 ┌─────────────────────────┐       ┌─────────────────────────┐     ┌─────────────────────────┐
 │   Pod A (Old v1.0.0)    │ ────► │ Terminating...          │ ──► │          [GONE]         │
 ├─────────────────────────┤       ├─────────────────────────┤     ├─────────────────────────┤
 │   Pod B (Old v1.0.0)    │ ────► │ Active Traffic          │ ──► │ Terminating...          │
 └─────────────────────────┘       ├─────────────────────────┤     ├─────────────────────────┤
                                   │ Pod C (New v1.1.0)      │ ──► │ Active Traffic          │
                                   └─────────────────────────┘     └─────────────────────────┘

🚨 EMERGENCY ROLLBACK COMMAND (helm rollback) ───────────────────────────────────────────────┐
   Instantly halts active state and reverses this entire sequence step-by-step                │
◄────────────────────────────────────────────────────────────────────────────────────────────┘
```
#### 🔄 Phase 1: Rolling Out an Upgrade (New Code / New Version)
Imagine the development team has fixed a bug and built a new Docker image tagged 1.26.0. They need this deployed to Production.

Step 1: Update your Environment Configuration
Instead of touching your core templates, simply modify your environment override file (env-prod.yaml) with the new image tag and configurations:
```
replicaCount: 5

resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "1024Mi"

appEnv:
  DB_HOST: "prod-secure-cluster.database.azure.com"
  LOG_LEVEL: "info"       # Bumping log level from error to info
  NEW_PATCH_VERSION: "1.26.0" # Adding a new tracking flag variable
```
Step 2: Execute the Upgrade Command
Run the upgrade command pointing to your production environment. Helm will automatically calculate the delta between what is currently running and what is defined in your updated env-prod.yaml:

```
helm upgrade order-api-prod ./order-processor \
  --namespace team-alpha-prod \
  -f env-prod.yaml
```
Step 3: Watch the Rolling Update Happen Live
Open a secondary terminal window and run this command to watch the Kubernetes deployment controller systematically swap the pods without dropping a single packet of user traffic:
```
kubectl get pods -n team-alpha-prod -w
```
------------------
### 📜 Phase 2: Auditing Release Histories
Every time you execute a helm upgrade, Helm creates an immutable backup record called a Revision. Let's check the history ledger for your production stack:
```
helm history order-api-prod -n team-alpha-prod
```
Understanding the History Output:
Your terminal will print out an audit trail that looks like this:
```
 REVISION    UPDATED                 STATUS      CHART             APPVERSION  DESCRIPTION
    1      Mon Jun 1 14:00:00 2026 superseded order-processor-1.0.0 1.0.0        Install complete
    2      Mon Jun 1 14:40:00 2026  deployed  order-processor-1.0.0	1.0.0	        Upgrade prepared
 ```
- superseded: This means version 1 is no longer actively running, but its configuration snapshot is saved safely in the cluster.
- deployed: This represents your current live production environment.

### 🚨 Phase 3: Executing an Emergency Rollback
Ten minutes after upgrading to Revision 2, an alert goes off. The application is running slowly or throwing database exceptions. You must revert to the old version immediately.
roll back to Revision 1.
```
helm rollback order-api-prod 1 -n team-alpha-prod
```
Verify the Rollback History Ledger
```
helm history order-api-prod -n team-alpha-prod
```

-----------------
To Delete
```
# Safely removes workloads and cleans up cluster resources
helm uninstall order-api-dev -n team-alpha-dev
helm uninstall order-api-prod -n team-alpha-prod

# Delete namespaces
kubectl delete namespace team-alpha-dev team-alpha-prod
```


