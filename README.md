# Setting up GPU Instance as Hybrid Node

## Getting Started

```bash
export KUBE_CONFIG_PATH=~/.kube/config

# Deploy AWS infrastructure using Terraform
cd terraform

terraform init
terraform apply --auto-approve

$(terraform output -raw eks_update_kubeconfig)
```

#### Setup Karpenter and Kube Proxy

We shall use Karpenter to provision nodes on the Cloud. While, we need to setup Kube Proxy to run only on Cloud Nodes. Cilium will be used to proxy on the Hybrid Nodes.

**Step 1:** Apply the Karpenter configuration:
```bash
kubectl apply -f generated-files/karpenter.yaml
```

**Step 2:** Configure Kube Proxy with the correct region affinity:
```bash
# Replace "ap-southeast-1" with your AWS region
kubectl patch ds -n kube-system kube-proxy -p '{"spec": {"template": {"spec": {"affinity": {"nodeAffinity": {"requiredDuringSchedulingIgnoredDuringExecution": {"nodeSelectorTerms": [{"matchExpressions": [{"key": "topology.kubernetes.io/region", "operator": "In", "values": ["ap-southeast-1"]}]}]}}}}}}}'
```

> **Important:** Make sure to replace `ap-southeast-1` in the command above with the AWS region you're using for your deployment. This ensures that kube-proxy pods are scheduled only on nodes in your specific region.

#### VPN Server Setup
We use Wireguard for site-to-site VPN in this demo. This is how our EKS Cluster communicates with the Raspberry Pi.  
We setup Wireguard by installing the Wireguard server on an EC2 instance running in our AWS Account. Then we will setup the Wireguard client on our on-prem device.  

**Step 1:** Review the Wireguard setup instructions in the SETUP_VPN.md file that was generated in your terraform directory.
```bash
cat generated-files/SETUP_VPN.md
```

**Step 2:** Get the VPN server's public IP address using Terraform
```bash
terraform output vpn_server_public_ip
```
> **Note:** Save this IP address as you will need it for the Raspberry Pi Wireguard configuration.

**Step 3:** Connect to VPN server using SSM
```bash
$(terraform output -raw connect_vpn_server)
```

**Step 4:** Follow the instructions from SETUP_VPN.md to set up Wireguard on the VPN server.

**Step 5:** Get the required key values for Raspberry Pi setup
```bash
# Switch to root user
sudo -i

# Get the public key
cat /etc/wireguard/public.key

# Get the client private key
cat /etc/wireguard/client-private.key
```
> **Note:** Save these key values as you will need them later for the Raspberry Pi Wireguard configuration.

---

### 2. GPU Setup  

GCP Instance [us-west-1b] --> CIDR: 172.16.0.0/20 --> g2-standard-16 + Debian GNU/Linux 12 (bookworm)

1. **Install Wireguard:**
```bash
sudo apt update && sudo apt install -y wireguard
sudo mkdir -p /etc/wireguard
```

2. **Create WireGuard Configuration:**
```bash
sudo nano /etc/wireguard/wg0.conf
```

Add the following configuration (replace placeholders):
```ini
[Interface]
PrivateKey = <client-private.key>
Address = 10.130.128.2/17

[Peer]
# Public key from AWS server (/etc/wireguard/public.key)
PublicKey = <public.key>
# Your EC2 instance's public IP
Endpoint = <ec2-public-ip>:51820
# WireGuard server network, AWS VPC CIDR & EKS Service CIDR
AllowedIPs = 10.130.128.1/17,10.129.0.0/16,10.128.0.0/16
PersistentKeepalive = 25
```

3. **Enable and Start Wireguard:**
```bash
sudo echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Verify connection
sudo wg show

sudo ip link set dev wg0 mtu 1420
```

4. **Complete Node Setup:**
```bash
# View setup instructions from the folder containing your terraform files
cat SETUP_NODE.md
```

5. **Setup Driver Plugin**
```bash
sudo nvidia-ctk runtime configure --runtime=containerd --nvidia-set-as-default
sudo systemctl restart containerd kubelet
```

---

### 3. Setup CNI

1. **Install Helm** (if not already installed):
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

2. **Add Cilium Repository:**
```bash
# New installation
helm repo add cilium https://helm.cilium.io/

# Or update existing
helm repo update
```

3. **Install Cilium:**
```bash
helm install cilium cilium/cilium \
    --version 1.17.1 \
    --namespace kube-system \
    --values generated-files/cilium-values.yaml 
```

4. **Configure CoreDNS:**
Wait for Cilium to be deployed (so that our Hybrid Node is in a Ready state)
```bash
# First get the endpoint
ENDPOINT=$(terraform output -raw eks_cluster_endpoint)

# Then use it in the patch command
cat << 'EOF' | kubectl patch deployment coredns -n kube-system --patch-file /dev/stdin
{
  "spec": {
    "strategy": {
      "rollingUpdate": {
        "maxSurge": 0,
        "maxUnavailable": 1
      }
    },
    "replicas": 3,
    "template": {
      "spec": {
        "affinity": {
          "podAntiAffinity": {
            "preferredDuringSchedulingIgnoredDuringExecution": [
              {
                "podAffinityTerm": {
                  "labelSelector": {
                    "matchExpressions": [
                      {
                        "key": "k8s-app",
                        "operator": "In",
                        "values": [
                          "kube-dns"
                        ]
                      }
                    ]
                  },
                  "topologyKey": "kubernetes.io/hostname"
                },
                "weight": 100
              },
              {
                "podAffinityTerm": {
                  "labelSelector": {
                    "matchExpressions": [
                      {
                        "key": "k8s-app",
                        "operator": "In",
                        "values": [
                          "kube-dns"
                        ]
                      }
                    ]
                  },
                  "topologyKey": "topology.kubernetes.io/zone"
                },
                "weight": 50
              }
            ]
          }
        }
      }
    }
  }
}
EOF

kubectl patch deployment coredns -n kube-system --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "coredns",
          "env": [
            {
              "name": "KUBERNETES_SERVICE_HOST",
              "value": "'$ENDPOINT'"
            },
            {
              "name": "KUBERNETES_SERVICE_PORT",
              "value": "443"
            }
          ]
        }]
      }
    }
  }
}'

kubectl rollout restart deployment coredns -n kube-system
```
Do double check to see if there is a CoreDNS running on the Hybrid Node - if not delete one of the pods to let it be provisioned on the Hybrid Node.

Finally, setup kube-dns:
```bash
kubectl patch svc kube-dns -n kube-system --type=merge -p '{
  "spec": {
    "trafficDistribution": "PreferClose"
  }
}'
```

---

## Verification

```bash
# Check node status
kubectl get nodes

# View running pods
kubectl get pods -A
```

✅ Check your AWS Console - a new node should appear in your EKS Cluster once Cilium is properly configured.

🎉 **Congratulations!** Your Raspberry Pi is now a Hybrid Node in your EKS Cluster.

