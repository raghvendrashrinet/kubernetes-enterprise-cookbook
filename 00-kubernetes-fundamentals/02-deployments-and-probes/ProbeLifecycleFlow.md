### Complete Kubernetes Probe Lifecycle Flow
#### If your container usually starts in more than ```initialDelaySeconds+failureThreshold×periodSeconds``` you should specify a startup probe that checks the same endpoint as the liveness probe  
- The readiness probe might be the same as the liveness probe, but the existence of the readiness probe in the spec means that the Pod will start without receiving any traffic and only start receiving traffic after the probe starts succeeding.
- You can also use a readiness probe to let a container take itself down for maintenance, by checking an endpoint specific to readiness that is different from the liveness probe.
- When your app has a strict dependency on back-end services, you can implement both a liveness and a readiness probe. The liveness probe passes when the app itself is healthy, but the readiness probe additionally checks that each required back-end service is available. 
#### One Implementation could be  Liveness and Readiness probes hit two completely different HTTP endpoints (or run different check scripts), because they are looking for two entirely different types of failures.
1. The Readiness Endpoint (/healthz/ready)
   What the code checks inside: It tests external dependencies. It pings the database,
   The Business Logic: If the database goes down, this endpoint returns an HTTP 503 Service Unavailable. Kubernetes instantly cuts traffic to this Pod so users don't see broken pages, but it leaves the container running so it can reconnect automatically
2. The Liveness Endpoint (/healthz/live)
   What the code checks inside: It checks only if the application process itself is responsive and moving forward. It does not check the database. It often just returns a hardcoded HTTP 200 OK instantly.

The Business Logic: If the database goes down, this endpoint still returns 200 OK. Why? Because restarting the application won't fix a broken database!  
```
Container Created
       │
       ▼
┌────────────────────────────────────────────────────────┐
│ 1. STARTUP PROBE INITIATED                            │
│    (Readiness & Liveness Probes are DISABLED)          │
└───────────────────────┬────────────────────────────────┘
                        │
                        ├─► [Action Type Check: httpGet / tcpSocket / exec]
                        │   Waits: initialDelaySeconds
                        │
                        ▼
               Did it Pass? (Status OK / Exit 0)
                 ├── YES ──► (Startup Probe stops forever; hands off control)
                 │           │
                 └── NO ───► Waits: periodSeconds
                             │
                             ▼
                     Reached failureThreshold?
                       ├── NO  ──► Loops back, checks again
                       └── YES ──► Pod KILLED & restarted (CrashLoopBackOff)
                               │
                               ▼
┌──────────────────────────────┴─────────────────────────┐
│ 2. READINESS & LIVENESS PROBES ACTIVATED               │
│    (Both run continuously and concurrently)            │
└──────────────┬──────────────────────────┬──────────────┘
               │                          │
               ▼                          ▼
┌───────────────────────┐   ┌───────────────────────┐
│    READINESS PROBE    │   │    LIVENESS PROBE     │
│  Continually Monitors │   │  Continually Monitors │
│   Transient Health    │   │     Process Death     │
└───────────┬───────────┘   └───────────┬───────────┘
            │                           │
    Did a check fail?           Did a check fail?
┌───────────┴───────────┐   ┌───────────┴───────────┐
│ YES                   │   │ YES                   │
▼                       ▼   ▼                       ▼
Remove Pod IP             Kill Container & Restart
from Endpoints            (Hard reset of the pod)
(App stays alive; Traffic cuts)    


