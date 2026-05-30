### A Kubernetes Service. A Service provides a permanent IP address and a stable internal DNS name (http://catalog-service). 
It uses standard metadata selectors to act as a layer-4 load balancer, dynamically routing packets only to pods that are passing their health checks.

### 📄 Step 1: Create the Manifest File
Create a file named services-networking.yaml inside your local directory:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-backend-api
  namespace: team-alpha
  labels:
    app: catalog-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: catalog-api
  template:
    metadata:
      labels:
        app: catalog-api
    spec:
      containers:
      - name: api-engine
        image: nginx:alpine
        ports:
        - containerPort: 80
          name: http-port
---
# 1. STANDARD INTERNAL SERVICE (ClusterIP)
apiVersion: v1
kind: Service
metadata:
  name: catalog-service
  namespace: team-alpha
spec:
  type: ClusterIP # Only accessible from inside the cluster for security
  ports:
  - port: 8080       # The port the service listens on inside the cluster
    targetPort: 80   # The actual port exposing the app container process
    protocol: TCP
    name: http
  selector:
    app: catalog-api # Dynamically routes to any pod carrying this label
---
```
