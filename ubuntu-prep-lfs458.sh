#!/bin/bash

# LFS458 VM prep script
apt-get update && apt-get upgrade -y
apt-get install -y vim curl apt-transport-https vim git wget software-properties-common lsb-release ca-certificates -y

swapoff -a
modprobe overlay
modprobe br_netfilter
cat << EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update && apt-get install containerd.io -y
containerd config default | tee /etc/containerd/config.toml
sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
systemctl restart containerd

echo \
"deb http://apt.kubernetes.io/ kubernetes-xenial main"\
| sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

curl -s \
https://packages.cloud.google.com/apt/doc/apt-key.gpg \
| apt-key add -

apt-get update
apt-get install -y kubeadm=1.27.1-00 kubelet=1.27.1-00 kubectl=1.27.1-00
apt-mark hold kubelet kubeadm kubectl

# on control plane node only
# kubeadm init --pod-network-cidr  192.168.0.0/16 --apiserver-bind-port 443 --kubernetes-version 1.27.1 | tee kubeadm-init.out
# kubeadm join 172.31.18.144:443 --token q6ygdx.r0vh26cuepxtmj3n --discovery-token-ca-cert-hash sha256:0c7e0912ab17b717a1f2fd3cf0996dde5a5c06029140131c5d2a14cf0828b7a6 
