# LFS458


```
kubeadm init --pod-network-cidr  192.168.0.0/16 --apiserver-bind-port 443 --kubernetes-version 1.27.1 | tee kubeadm-init.out
```

## log out of root, add the 

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/ams0/cka/main/cilium-cni.yaml
```

## go to the worker node and run the join command (within 2 hours)

```
kubeadm join 172.31.18.144:443 --token a1zxfy.xro3ah7h0751vi3n \
--discovery-token-ca-cert-hash sha256:0c7e0912ab17b717a1f2fd3cf0996dde5a5c06029140131c5d2a14cf0828b7a6 
```


### Day3

What did we learn
- Installation via Kubeadm (fixed the API server port)
- Deployments, pods, replicasets
- Architecture, components on cp and worker
- Backup and restore of etcd
- upgrade of components via kubeadm (cordon/drain/update/uncordon)
- Networking basics (service types)
- Resources, quotas, limits
- Network policies

What will we learn
- Limits and requests

Install metrics-server

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

LimitRange

```
apiVersion: v1
kind: LimitRange
metadata:
  name: low-resource-range
spec:
 limits:
 - default:
     cpu: 1
     memory: 500Mi
   defaultRequest:
     cpu: 0.5
     memory: 100Mi
   type: Container
```

Metrics-server

```
kubectl apply -f https://raw.githubusercontent.com/ams0/cka/main/metrics-server.yaml
```

Aliases

```
wget https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases
source .kubectl_aliases
```

## Tips

use `:set paste` in vim


 kubectl expose deploy nginx --port=80 --dry-run=client -o yaml > svc.yaml
 kubectl create deploy alessandro --image=nginx --dry-run=client -o yaml

## Resources

https://killer.sh/
https://killercoda.com/
https://drive.google.com/drive/folders/1qfPY7UAbRiLnXiw5nFHpmXr5uGC9yAsz?usp=drive_link
https://github.com/MuhammedKalkan/OpenLens
file:///Users/alessandro/Downloads/troubleshooting-kubernetes.en_en.v3.pdf
https://k9scli.io/
https://github.com/ahmetb/kubernetes-network-policy-recipes/
https://editor.networkpolicy.io/
https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/
https://github.com/FairwindsOps/rbac-lookup
https://www.santana.dev/book-club

## Ingress

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-test
  annotations:
    nginx.ingress.kubernetes.io/service-upstream: "true"
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: www.external.com
    http:
      paths:
      - backend:
          service:
            name: nginx
            port:
              number: 80
        path: /
        pathType: ImplementationSpecific
```




## Prep script for Ubuntu VM

Run this script to replicate the steps in 3.1 1 to 19; we will skip manipulating the hosts file and use IPs instead; 
```
wget https://raw.githubusercontent.com/ams0/cka/main/ubuntu-prep-lfs458.sh -O prep-script.sh
chmod +x prep-script.sh
./prep-script.sh
```

```
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
```