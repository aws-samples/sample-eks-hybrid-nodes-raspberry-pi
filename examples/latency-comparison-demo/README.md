# EKS Hybrid Nodes Latency Comparison Demo

This demo showcases the latency differences between pods running on AWS EKS cloud nodes and pods running on Raspberry Pi hybrid nodes.

## Overview

The demo consists of:

1. **API Services**: Identical API services deployed on both cloud and Pi nodes
2. **Frontend**: A web UI running on the Pi that calls both API services and visualizes the latency differences

## Prerequisites

- EKS cluster with both cloud nodes and Raspberry Pi hybrid nodes
- `kubectl` configured to access your cluster
- Docker and container registry access (e.g., ECR) for building and pushing images

## Deployment

```bash
# Apply Kubernetes manifests
kubectl apply -f namespace.yaml
kubectl apply -f pi-api.yaml
kubectl apply -f cloud-api.yaml
kubectl wait --for=condition=available deployment/api-cloud -n latency-demo --timeout=60s
kubectl apply -f frontend.yaml
```

### 3. Access the Demo

The frontend service is exposed as a NodePort on port 30080. You can access it using your Raspberry Pi's IP address (as long as the Pi and your device are on the same network):

```bash
HYBRID_NODE=$(kubectl get nodes -l eks.amazonaws.com/compute-type=hybrid -o jsonpath='{.items[0].metadata.name}')
PI_IP=$(k get nodes $HYBRID_NODE -o yaml | grep 'address: ' | head -1 | awk '{print $3}')
echo "Access frontend at http://$PI_IP:30080"
```

## Using the Demo

1. Open the web UI in your browser
2. Click "Start Testing" to begin measuring latency between cloud and Pi nodes
3. Adjust the test interval and artificial delay as needed
4. Observe the real-time latency comparison chart and statistics

![alt text](../../src/image.png)

## Customization

- **Test Interval**: Adjust how frequently latency tests are performed
- **Artificial Delay**: Add simulated processing time to better visualize differences

## Cleanup

```bash
kubectl delete namespace latency-demo
```
