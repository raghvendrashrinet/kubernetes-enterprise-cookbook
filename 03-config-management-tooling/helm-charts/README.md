Helm is the package manager for Kubernetes that simplifies deploying, upgrading, and managing applications using reusable “charts.” To go from beginner to production-grade usage,
Install Helm:
- Linux/macOS: brew install helm or curl script.
- Windows: choco install kubernetes-helm or scoop install helm.
- Verify installation: helm version
Core concepts:
> - Chart = packaged Kubernetes resources.
> - Repository = collection of charts (e.g., Bitnami).
> - Release = deployed chart instance in your cluster.

Working with Charts  
- Add repositories:  
> helm repo add bitnami https://charts.bitnami.com/bitnami
- Search charts:  
> helm search repo nginx
- Install apps:  
> helm install my-nginx bitnami/nginx
- Check Installed Chart
> helm list
- Inspect charts:
> helm show chart bitnami/nginx

#### Customization
1. values.yaml — override defaults.
```
    helm install my-nginx bitnami/nginx -f values.yaml
```

#### Chart Development
Build your own chart
1. Create a chart:

```bash
helm create myapp
```
2. Explore structure:
```
templates/ → Kubernetes manifests with Go templating

values.yaml → default configs
```
3. Exercise:

Modify deployment.yaml to use your own Docker image.

Install with:
```
helm install myapp ./myapp
```
