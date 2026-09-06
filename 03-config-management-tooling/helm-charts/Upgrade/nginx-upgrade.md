## create and deploy nginx , upgrade the imgae

### helm create, by default create an nginx template\
```
helm create new-chart 
```
### deoloy nginx
```
 helm install nginx-1 ../new-chart 
```
### check deployment
```
 helm ls

 kubectl get pods
 ```
 

### Upgrade the nginx image
#### step 1. Change the image tag in the values.yaml 
```yaml
# values.yaml
image:
  repository: nginx
  # This sets the pull policy for images.
  pullPolicy: IfNotPresent
  # Overrides the image tag 
  tag: "1.29.1"
```
#### step 2.Test what Helm will generate
```
helm upgrade --install nginx1 ./mychart --set image.tag=1.29.1 --dry-run
```

#### step 3. Upgrade production
```
helm upgrade nginx1 ./mychart -n production
```
Or if you want to override the values file through cli
```
helm upgrade nginx1 ./mychart \
  --set image.tag=1.30.0 \
  -n production
```
> [!NOTE]
> `appVersion`: change app version from 1.16.0 to  appVersion: "1.16.1"  
> `Chart Version`: you should usually change it when you make a new chart release  
#### step 4. Watch the rollout
```
kubectl rollout status deployment/nginx1 -n production

kubectl get pods -n production
```

#### step 5. If the new version has a problem
Check releases:
```
helm history nginx1 -n production
```
**Then rollback:**
```
helm rollback nginx1 <REVISION> -n production
```

For example:
```
REVISION    STATUS
1           superseded
2           deployed    ← new nginx
```
If revision 2 is bad:

```
helm rollback nginx1 1 -n production
```
---
## What to check what has changed between Helm revisions
`Use ` helm diff
> Note: you need to install helm diff plugin  first
 - 1.See the revision history
 ```
 helm history nginx1
 ```
 2. See what changed between revisions
 ```
 helm diff revision nginx1 1 2
 ```
 3. Check  Helm manifest
 ```
 helm get manifest nginx1
 ```
 
 ---

A typical production workflow
```
Developer changes
      ↓
values.yaml
      ↓
nginx:1.29.1
      ↓
helm template / helm diff
      ↓
Code review
      ↓
CI/CD pipeline
      ↓
helm upgrade
      ↓
Kubernetes rolling update
      ↓
Health checks
      ↓
New Pods running
```

