### Setup Raspberry Pi

- Install tools
```
sudo su ubuntu
cd ~

sudo snap install aws-cli --classic

sudo snap remove amazon-ssm-agent
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_arm64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/arm64/nodeadm'
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
  hybrid: 
    ssm:
      activationCode: ${activation_code}
      activationId: ${activation_id}
EOF
```

- Setup Node
```
sudo nodeadm install ${version} --credential-provider ssm
sudo nodeadm init -c file://nodeConfig.yaml
sudo systemctl daemon-reload
export KUBECONFIG=/var/lib/kubelet/kubeconfig
```
If there is a DescribeCluster error, just rerun the above code chunk again.