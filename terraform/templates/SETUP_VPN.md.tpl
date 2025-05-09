### Setup Wireguard

- Install Wireguard and setup keys
```
sudo su ubuntu
cd ~

sudo apt update && sudo apt install -y wireguard

wg genkey | sudo tee /etc/wireguard/private.key
sudo chmod go= /etc/wireguard/private.key
sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key

wg genkey | sudo tee /etc/wireguard/client-private.key
sudo chmod go= /etc/wireguard/client-private.key
sudo cat /etc/wireguard/client-private.key | wg pubkey | sudo tee /etc/wireguard/client-public.key
```

- Setup wg0 config
```
sudo bash -c 'private_key=$(cat /etc/wireguard/private.key); cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $private_key
Address = 10.200.0.1/24
ListenPort = 51820
SaveConfig = true
EOF'
```

- Setup IP table and route
```
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Configure iptables for forwarding and NAT
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
```

- Start Wireguard
```
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

sudo ip route add ${remote_node_cidr} dev wg0
sudo ip route add ${remote_pod_cidr} dev wg0
```

- Add peer to wg0
```
sudo wg set wg0 peer $(sudo cat /etc/wireguard/client-public.key) allowed-ips 0.0.0.0/0
```

- Create connection from the client

- Check the status on the server with `sudo wg show`