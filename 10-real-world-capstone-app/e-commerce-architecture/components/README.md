## Production-Level Sidecar Pattern Project
### Project Overview: Zero-Trust Legacy App Migration
**The Scenario**: You are deploying a legacy, compliance-heavy enterprise application (like a banking transaction API) that cannot natively handle SSL/TLS termination, lacks proper OAuth2/OIDC authentication, and writes logs directly to a local file path instead of stdout

Instead of rewriting the legacy application code, we use a Multi-Sidecar Pattern to inject enterprise capabilities at the Kubernetes layer.

#### The Architecture
The single Pod will contain three containers sharing the same network namespace and local volumes:
1. **Main Application Container:** Runs the unencrypted legacy app on localhost:8080.

2. **Ambassador/Proxy Sidecar (Envoy/Nginx):** Handles incoming public HTTPS traffic, terminates SSL/TLS using certificates from cert-manager, validates JWT tokens, and proxies clean traffic locally to the main app.

3.**Log Forwarder Sidecar (Fluent Bit):** Tails a shared emptyDir volume where the legacy app writes raw logs, processes them, and ships them securely to Elasticsearch/Splunk.

---
Key Points
- Lifecycle Management (Native Sidecars): Explain how Kubernetes native sidecars (initContainers with restartPolicy: Always) ensure that the security and logging sidecars spin up before the primary application starts, preventing unencrypted traffic windows or lost initial boot logs.
- Shared Networking (localhost): Detail how the proxy container can communicate with the application over 127.0.0.1 instantly because containers inside the same Pod share the same network namespace.
- Resource Isolation: Highlight how allocating distinct CPU/Memory constraints to the sidecars ensures that a log-forwarding backup or a heavy traffic spike on Envoy won't starve the core business application container
 
  
