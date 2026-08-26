
```
[ User / kubectl ]
               │
               ▼
┌─────────────────────────────┐
│ ✦  1. Authentication        │ ──── (Handled by API Server: verifies tokens, TLS certs) [00:21:02]
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ ✦  2. Authorization         │ ──── (Handled by API Server: evaluates RBAC permissions) [00:21:02]
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ ✦  3. Mutating Webhooks     │ ──── (Triggered by API Server: calls external hooks like Istio) [00:21:31, 00:59:43]
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ ✦  4. Schema Validation     │ ──── (Handled by API Server: checks YAML structure & fields)
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ ✦  5. Validating Webhooks   │ ──── (Triggered by API Server: validates rules/ResourceQuotas) [00:21:31, 00:29:48]
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ ✦  6. Save to etcd          │ ──── (Handled by API Server: writes final spec to storage) [00:21:13]
└──────────────┬──────────────┘
               │
        [ API Server Done ]
               │
               ▼
┌─────────────────────────────┐
│    7. Kube-Scheduler        │ ──── (External: selects worker node for the pod)
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│    8. Kubelet Execution     │ ──── (External: worker node daemon starts containers) [00:19:25]
└─────────────────────────────┘

```


