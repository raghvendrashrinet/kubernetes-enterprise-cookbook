### Complete Kubernetes Probe Lifecycle Flow

#### Liveness and Readiness probes hit two completely different HTTP endpoints (or run different check scripts), because they are looking for two entirely different types of failures.
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


