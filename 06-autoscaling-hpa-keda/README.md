### To meet sudden or time based surge - Autoscaling!
Kubernetes uses a native automated scaling matrix split across two completely different layers:
1. The Pod Layer (Horizontal Pod Autoscaler - HPA): Adds more replicas of your application when traffic spikes.
2. The Infrastructure Layer (Cluster Autoscaler): Adds more physical virtual machines (cloud nodes) to the cluster when there is no room left to house your new pods.
