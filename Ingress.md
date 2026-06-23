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
What you will get:  
1. The Controller Pod (pod/my-ingress-controller-...): This is the actual NGINX reverse-proxy instance executing your routing logic.
2. The Cloud Load Balancer Service (service/my-ingress-controller-...): You will see a service of type: LoadBalancer
3.  *  The Cloud Load Balancer Service (service/my-ingress-controller-...): You will see a service of type: LoadBalancer

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
        image: nginxdemos/hello:plain
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





    
  
