#!/bin/bash

# Exit on error

echo "Starting Raspberry Pi cleanup..."

# Stop services
echo "Stopping services..."
sudo systemctl stop kubelet || true
sudo systemctl stop containerd || true
sudo systemctl stop amazon-ssm-agent || true

# Remove kubernetes directories
echo "Removing Kubernetes directories..."
sudo rm -rf /etc/kubernetes/ 
sudo rm -rf /var/lib/kubernetes/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/run/kubernetes/

# Remove CNI
echo "Removing CNI..."
sudo rm -rf /etc/cni/
sudo rm -rf /opt/cni/
sudo rm -rf /var/lib/cni/

# Remove binaries
echo "Removing binaries..."
sudo rm -f /usr/bin/nodeadm
sudo rm -f /usr/bin/kubelet
sudo rm -f /usr/bin/kubectl
rm amazon-ssm-agent.deb

# Remove containerd
echo "Removing containerd..."
sudo rm -rf /etc/containerd
sudo rm -rf /var/lib/containerd/

# Disable services
echo "Disabling services..."
sudo systemctl disable kubelet
sudo systemctl disable containerd
sudo rm -f /etc/systemd/system/kubelet.service
sudo rm -f /etc/systemd/system/containerd.service

# Remove SSM agent
echo "Removing SSM agent..."
sudo apt-get remove -y amazon-ssm-agent || true
sudo rm -rf /var/lib/amazon/ssm

# Remove config files
echo "Removing config files..."
sudo rm -f ~/nodeConfig.yaml
sudo rm -rf ~/.kube

# Remove WireGuard
echo "Removing WireGuard..."
sudo systemctl stop wg-quick@wg0 || true
sudo systemctl disable wg-quick@wg0 || true
sudo rm -f /etc/wireguard/wg0.conf

# Clean up system
echo "Cleaning up system..."
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Remove AWS CLI
echo "Removing AWS CLI..."
sudo snap remove aws-cli || true

echo "Cleanup completed! System will reboot in 5 seconds..."
sleep 5
sudo reboot
