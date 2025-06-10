### Setup Node 

- Install tools
```
sudo su ubuntu
cd ~

sudo snap install aws-cli --classic
curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm'
sudo mv nodeadm /usr/bin/nodeadm
sudo chmod +x /usr/bin/nodeadm
```

- Create nodeConfig.yaml
```
cat <<EOF > nodeConfig.yaml
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${cluster_name}
    region: ${region}
  kubelet:
    flags:
      - --node-labels=topology.kubernetes.io/zone=onprem
      - --resolv-conf=/run/systemd/resolve/resolv.conf
  hybrid: 
    ssm:
      activationCode: ${activation_code}
      activationId: ${activation_id}
EOF
```

- Setup Node
```
sudo nodeadm install 1.32 --credential-provider ssm
sudo nodeadm init -c file://nodeConfig.yaml
sudo systemctl daemon-reload
```