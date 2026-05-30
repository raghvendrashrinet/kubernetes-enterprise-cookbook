# Concept 04: Configuration Decoupling via ConfigMaps & Secrets

## 💡 Key Architectural Concepts
* **Twelve-Factor App Methodology:** Enterprise design patterns state that an application's code must remain completely decoupled from its execution configurations. This allows the exact same container image to run safely in Dev, Staging, and Production.
* **ConfigMaps:** Used to store non-confidential configuration key-value pairs. Can be injected as environment variables or mounted directly as flat text configuration files via a projected volume.
* **Secrets:** Used to isolate sensitive tokens. Standard Kubernetes secrets use Base64 encoding. 

> ⚠️ **Production Security Note:** Base64 encoding is *not* encryption. Anyone with access to the namespace API can decode secrets. In an enterprise AKS cluster, you should integrate this with the *Azure Key Vault Secrets Provider* to pull secret tokens directly from an HSM hardware vault onto the pod memory space without saving them to the cluster database.

## 🚀 How to Execute & Verify
1. Deploy the configurations along with the test workload:
   ```bash
   kubectl apply -f configmaps-secrets.yaml

🏢 The Real-World Production Problem
Your application needs to connect to an external payment API and a database. The API endpoint changes based on the environment (e.g., dev.api.payment.com vs prod.api.payment.com), and the database requires a private, encrypted password. You need a way to inject these runtime configurations into your containers dynamically without changing a single line of your application code or container images.   

The Enterprise Solution
Decouple configurations entirely using ConfigMaps and Secrets:

ConfigMap: Holds non-sensitive data like environment variables, feature flags, and endpoint URLs in plain text.

Secret: Holds sensitive cryptographic material, tokens, and API keys encoded in Base64 (and encrypted at rest by the control plane).

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: team-alpha
data:
  PAYMENT_API_URL: "https://dev.api.payment.com/v2"
  LOG_LEVEL: "debug"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-db-secret
  namespace: team-alpha
type: Opaque # Standard generic type for user-defined arbitrary text secrets
stringData:
  # Using stringData allows you to put plain text here; K8s will Base64 encode it automatically
  DATABASE_PASSWORD: "VaultSecurePassword2026!"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-worker
  namespace: team-alpha
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-worker
  template:
    metadata:
      labels:
        app: payment-worker
    spec:
      containers:
      - name: worker
        image: nginx:alpine
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "100m"
            memory: "128Mi"
        env:
        # 1. Injecting individual plain text values from a ConfigMap
        - name: PAYMENT_ENDPOINT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: PAYMENT_API_URL
        
        # 2. Injecting sensitive values securely from a Secret
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: app-db-secret
              key: DATABASE_PASSWORD
        
        # 3. Injecting a config file directly into the container filesystem
        volumeMounts:
        - name: config-volume
          mountPath: /etc/custom-app/config
      
      volumes:
      - name: config-volume
        configMap:
          name: app-config # Mounts all keys inside this configmap as separate files inside the directory
```
