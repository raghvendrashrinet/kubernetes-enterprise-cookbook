# Enterprise Stateful Workloads: Highly Available PostgreSQL

## 💡 Key Architectural Concepts
1. **StatefulSet vs. Deployment:** Unlike deployments where pods are anonymous and interchangeable, a StatefulSet maintains a sticky identity for each pod (numbered `postgres-0`, `postgres-1`, `postgres-2`). They are created sequentially (0, then 1, then 2) and terminated in reverse order.
2. **Headless Service Linkage:** By coupling the StatefulSet to `serviceName: "postgres-headless"`, CoreDNS generates stable network entries for individual pods. You can explicitly reach pod 0 at `postgres-0.postgres-headless.team-alpha.svc.cluster.local`.
3. **Volume Claim Templates:** Instead of pods sharing a single volume, the `volumeClaimTemplate` automatically creates a unique PersistentVolumeClaim (PVC) for each pod instance. If `postgres-1` crashes and reschedules on a completely different cluster node, AKS unmounts the corresponding Azure Disk from the old node and reattaches it to the new node seamlessly.

## 🚀 How to Execute & Verify
1. Provision the stateful architecture down into the cluster:
   ```bash
   kubectl apply -f postgres-statefulset.yaml
  
### The Real-World Production Problem
You need to deploy a highly available PostgreSQL database cluster inside your AKS environment.

If you use a Deployment, all replicas share or fight over the same storage disk, causing database corruption.

If a database replica crashes, it needs to boot back up with the exact same data and network name (postgres-0, postgres-1) so replication sync doesn't break.

The database primary instance needs to know the exact individual IP addresses of the standby nodes to replicate transactions—a standard load balancer proxy hides these IPs.

### 🛠️ The Enterprise Solution
Pair a Headless Service (which provides individual, stable DNS A-records for each pod) with a StatefulSet. The StatefulSet uses a volumeClaimTemplates block to automatically provision a completely unique, high-performance Azure Premium SSD (managed-csi) for each database instance.
#### 📄 Step 1: Create the StatefulSet Manifest
Create a file named postgres-statefulset.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  namespace: team-alpha
  labels:
    app: postgres
spec:
  clusterIP: None # <-- Essential: Bypasses the proxy, activates direct pod DNS routing
  ports:
  - port: 5432
    name: postgres
  selector:
    app: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: team-alpha
spec:
  serviceName: "postgres-headless" # Links directly to our headless network topology
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_DB
          value: "orders_db"
        - name: POSTGRES_USER
          value: "db_admin"
        - name: POSTGRES_PASSWORD
          value: "SuperSecretProductionPassword123!" # In Ch. 4, we'll migrate this to a K8s Secret!
        resources:
          requests:
            cpu: "250m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        volumeMounts:
        - name: pgdata
          mountPath: /var/lib/postgresql/data
  
  # Dynamic Storage Engine: Allocates an independent Azure Disk for every single pod spun up
  volumeClaimTemplates:
  - metadata:
      name: pgdata
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "managed-csi" # Native high-performance Azure Premium SSD CSI driver
      resources:
        requests:
          storage: 10Gi
```

2. Monitor the sequential creation process live (watch how it builds them one by one):

```Bash
kubectl get pods -n team-alpha -w

3. Verify that the CSI storage driver automatically spun up 3 distinct, isolated Azure Disk volumes:

```Bash
kubectl get pvc -n team-alpha

4. Test Network Determinism: Spin up a diagnostic container to verify stable DNS resolution targeting a single stateful instance:

```Bash
kubectl run net-test --rm -i --tty --image=busybox -n team-alpha -- restart=Never

Inside the container prompt, run a targeted ping or lookup:

```Bash
nslookup postgres-0.postgres-headless
```
## 🎯 Question
How do you run persistent stateful databases on modern container platforms?"*, you can hit them with this:
> *"deploy stateful systems using StatefulSets bound to a Headless Service. This guarantees deterministic network identifiers (`pod-0.service-name`) allowing cluster replication rings to form easily. Furthermore, then implement dynamic `volumeClaimTemplates` utilizing native Cloud CSI storage classes, ensuring that each database node gets its own unique persistent block disk attached to its specific lifecycle."*

Go ahead and commit these into your local storage path, push them up, and let's jump right back into the core track to tackle **`00-kubernetes-fundamentals/04-configmaps-and-secrets`**! Let me know when you're ready.
