## Industry Hybrid Pattern: Helm + Kustomize Post-Rendering
In enterprise environments, standard third-party Helm charts (e.g., Bitnami NGINX, Prometheus) often do not expose every custom field required by internal security teams (such as corporate Datadog sidecars, strict Pod Security Standards, or Istio annotations).

Instead of forking the public Helm chart, production teams use Kustomize to post-render the output of a Helm chart:

`overlays/production/kustomization.yaml`
(Using Kustomize with Helm)
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Pull standard upstream Helm chart as a base layer
helmCharts:
  - name: redis
    repo: https://charts.bitnami.com/bitnami
    version: 17.3.0
    releaseName: prod-redis
    valuesFile: values-prod.yaml

# Patch enterprise-required annotations directly onto rendered Helm resources
patches:
  - target:
      kind: StatefulSet
      name: prod-redis-master
    patch: |-
      - op: add
        path: /spec/template/metadata/annotations
        value:
          corp.security/vault-inject: "true"
          corp.security/compliance-tier: "pci-dss"
```
