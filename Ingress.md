## What is Kubernetes Ingress?
Think of Ingress as a traffic cop or a smart router for your cluster.  
- **Ingress Resource**: A collection of rules that defines how inbound connections should reach your internal cluster services.
- **Ingress Controller**: The actual software application that implements the rules (e.g., NGINX Ingress Controller, Traefik, HAProxy). Note: The Ingress resource does nothing without an active Controller running in the cluster.

 When you deploy an Ingress Controller (like NGINX or Traefik) into your Kubernetes cluster, a single cloud load balancer is provisioned to act as the front door for the controller itself.

 #### The Traffic Flow Architecture
 * 1. **The Cloud Load Balancer (Layer 4):**
      - When you install an Ingress Controller, it typically deploys a deployment of controller Pods and exposes them using a Kubernetes Service of type: LoadBalancer.
      -  This triggers your cloud provider (AWS, GCP, Azure) to spin up one single physical/virtual Cloud Load Balancer.
      -  This Cloud Load Balancer receives a single public IP address and routes all incoming raw TCP traffic on ports 80 (HTTP) and 443 (HTTPS) directly to your Ingress Controller Pods.
 * 2. **The Ingress Controller Pods (Layer 7 Routing)**
      - The Ingress Controller Pods (running NGINX, HAProxy, Envoy, etc.) are the "brains" of the operation.
      - The controller constantly watches the Kubernetes API for any Ingress routing rules you create or update.
      - When a rule is added (e.g., app.example.com/analytics $\rightarrow$ analytics-service), the controller automatically updates its internal reverse-proxy configuration files (like nginx.conf) without dropping connections.
     
* 3. Bypassing the ClusterIP Service (Direct to Pod)
     - A common misconception is that the Ingress Controller sends traffic to the Kubernetes Service object, which then sends it to the Pod.
     - Behind the scenes, most Ingress Controllers bypass the Service completely.
     - The controller queries the Kubernetes API for the actual IP addresses of the individual target Pods (known as Endpoints). It then loads-balances the HTTP requests directly to the Pod IPs. This eliminates an extra network hop inside the cluster, maximizing performance.

**Note**: Ingress controller are mostly available in a project pre configured by infra team, you just deifne ingress rule , this aut discovered by controller  


## Deploying new Ingress setup using HELM
**Step 1: Define Ingress Controller :**
  ** Installation using NGINX Ingress Repository
  ```
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
  ```
**Step 2: Install the Ingress Controller**  
  Now we deploy it. It is best practice to install it inside its own dedicated namespace (e.g., ingress-nginx).
 ```
  helm install my-ingress-controller ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

**Step 3: Verify the Created Infrastructure Objects**
  Let's check what Helm actually just created in your cluster. Run this command:  
```
  kubectl get all -n ingress-nginx
```
eg: Output from AKS Cluster
```

>kubectl get all -n  ingress-nginx
    NAME                                                                  READY   STATUS    RESTARTS   AGE
    pod/my-ingress-controller-ingress-nginx-controller-5c5766c6c9-kh26g   1/1     Running   0          4m18s

    NAME                                                               TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                      AGE
    service/my-ingress-controller-ingress-nginx-controller             LoadBalancer   10.0.104.237   20.235.194.119   80:30336/TCP,443:30363/TCP   4m18s
    service/my-ingress-controller-ingress-nginx-controller-admission   ClusterIP      10.0.109.57    <none>           443/TCP                      4m18s

    NAME                                                             READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/my-ingress-controller-ingress-nginx-controller   1/1     1            1           4m18s

    NAME                                                                        DESIRED   CURRENT   READY   AGE
    replicaset.apps/my-ingress-controller-ingress-nginx-controller-5c5766c6c9   1         1         1       4m18s

```

When you deploy the NGINX Ingress Controller, it is completely normal to see two services created in that namespace.

1. *The LoadBalancer Service (The Frontend Gateway)*:
   This is the actual entry point for all your external web traffic. It tells Azure to provision a physical Azure Load Balancer and assigns it the public EXTERNAL-IP
2. *The ClusterIP Service (The Internal Security Guard)*:
   This service is purely internal (<none> external IP) and is used for Validating Admission Webhooks.Traffic Flow: It does not handle your web traffic at all.

What else you will get:  
3. The Controller Pod (pod/my-ingress-controller-...): This is the actual NGINX reverse-proxy instance executing your routing logic.

--- 
### Now lets deploy project with ingress (rules) 
**Step 1: Deploy a Test Application & Service:**
Let's spin up a quick application (using an NGINX demo image) and expose it internally via a ClusterIP service. Save this as app-deploy.yaml:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-web
  template:
    metadata:
      labels:
        app: demo-web
    spec:
      containers:
      - name: web-container
        image: nginxdemos/hello:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: demo-web-service
spec:
  type: ClusterIP # Internal-only IP address
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: demo-web
```

Apply it to your cluster:
```
  kubectl apply -f app-deploy.yaml
```

## Step 2: Deploy the Ingress Object (The Routing Rule)
 Now, we deploy the actual Ingress resource. This connects your public-facing controller to your new demo-web-service. Save this as my-ingress.yaml:
 ```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  annotations:
    # Tells your cluster to map this rule specifically to the NGINX controller we deployed
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: hello-world.local   # The domain name we'll use to access the app
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-web-service # Points to our app service from Step 1
            port:
              number: 80
```

Apply routing rule:
```
 kubectl apply -f my-ingress.yaml
```
#### Step 3: Verify Everything works
Run this command to check if your Ingress rule has successfully attached itself to your controller's public IP:
`kubectl get ingress demo-ingress`  

The Expected Output:  
```
NAME           CLASS    HOSTS               ADDRESS          PORTS   AGE
demo-ingress   nginx    hello-world.local   192.168.X.X      80      30s
```
Test it Locally:

```
curl -H "Host: hello-world.local" http://<YOUR_INGRESS_CONTROLLER_EXTERNAL_IP>
```


---

Diferrent types of routing
-
Path based vs Host based:

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: routing-comparison
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  # --- PATH BASED SECTION ---
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```
 ## # --- HOST BASED SECTION ---
```
  # Note: These are separate entries in the 'rules' list
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
              
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```
---

#### Other Routing Strategy
2. **TLS Termination (SSL/HTTPS)**  
While technically a security feature, it dictates routing by handling encrypted traffic.  The Ingress Controller decrypts the HTTPS traffic at the edge and forwards unencrypted HTTP to the internal services.
- Concept: Terminates SSL using a certificate stored in a Kubernetes Secret.
- Use Case: Offloading the CPU-intensive encryption/decryption process from your application     pods and managing certificates centrally

```
spec:
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret-name
  rules:
  - host: secure.example.com
    # ... paths ...
```

3. **Traffic Splitting (Canary Deployments)**
   Advanced controllers (like NGINX, Traefik, or Istio) allow splitting traffic between different versions of the same service based on weights or headers

  - Concept: Send 90% of traffic to v1 (stable) and 10% to v2 (canary/new version).
  - Use Case: Safely testing new releases with a small subset of users before a full rollout. This often uses specific annotations `(e.g., nginx.ingress.kubernetes.io/canary-weight: "10")`

4. *Path Types (Matching Logic)*
   - `Exact`: Matches the URL path exactly (e.g., /api matches only /api, not /api/v1).
   - `Prefix`: Matches if the URL starts with the defined path (e.g., /api matches /api, /api/v1, /api/users).
   - `ImplementationSpecific`: Allows controller-specific matching logic (often used for Regex support in NGINX)

5. *Default Backend*
    A catch-all rule for traffic that does not match any specific host or path rules.

  - Concept: If no rules match, send traffic to a designated service. 
  - Use Case: Serving a generic "404 Not Found" page or a default landing page
  
