#!/bin/bash

RED="31"
GREEN="32"
BOLDGREEN="\e[1;${GREEN}m"
BOLDRED="\e[1;${RED}m"
ITALICRED="\e[3;${RED}m"
BOLDWHITE="\e[1;29m"
ENDCOLOR="\e[0m"

KUBEVER="1.24.5-00"

if [ "$EUID" -ne 0 ]
  then exec sudo "$0" "$@"; exit 0
fi

if [ "$EUID" -ne 0 ]
  then echo -e "${BOLDRED}This can only run as root. Use sudo.${ENDCOLOR}\nsudo ./setup.sh"
  exit
fi


hostname=$(cat /etc/hostname)

echo -e ""
echo -e "    ┌────────────────────────────┐"
echo -e "    │                            │"
echo -e "    │    ${BOLDGREEN}Kubernets Node Setup${ENDCOLOR}    │"
echo -e "    │     ${BOLDGREEN}VERSION ${KUBEVER} ${ENDCOLOR}     │"
echo -e "    │                            │"
echo -e "    │ This will setup your node  │"
echo -e "    │ to use in as a kubernetes  │"
echo -e "    │ IntegraNet cluster.        │"
echo -e "    │                            │"
echo -e "    └────────────────────────────┘"
echo -e ""
echo -e ""

read -p "Enter hostname [${hostname}]: " hostname

while ! [[ "$newcluster" =~ ^(y|n)$ ]] 
do
    read -p "Are you creating a new cluster? [y/n]: " newcluster
done 

if [[ "$newcluster" == 'y' ]]
then
  # find the right IP for the cluster
  read -a ipList <<< $(hostname -I)

  for i in "${!ipList[@]}"
  do
    index=$(($i+1));
    echo -e "${index}: ${ipList[$i]}"
     # do whatever on "$i" here
  done
  read -p "What is the IP/DNS that will used to k8s API? [${ipList[0]}]: " ip

  if [[ "$ip" == '' ]]
  then
    ip="${ipList[0]}"
  fi

  read -p "Enter a load balancer IP range [103.101.44.17/32]: " lb

  if [[ "$lb" == '' ]]
  then
    lb="103.101.44.17/32"
  fi

  #echo Your Hostname: $hostname
  #echo K8s API IP: $ip
  #echo Load Balaner IP Range: $lb
  #echo "Create new Cluster: $newcluster"

  lb=$(echo $lb | sed -e "s/\//\\\\\//")
fi

read -p "What is the domain name of your registry [hub.docker.com]: " registry

if [[ "$hostname" != '' ]]
then
  echo $hostname > /etc/hostname
  sudo hostname $hostname
fi

hostname=$(cat /etc/hostname)

echo -e "\n${BOLDGREEN}Installing Docker...${ENDCOLOR}"
apt-get -qq install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get -qq update
apt-get -qq install docker-ce docker-ce-cli containerd.io
# change cgroup of docker to systemd
#sed -i "s/^ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ --containerd=\/run\/containerd\/containerd.sock$/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ --containerd=\/run\/containerd\/containerd.sock --exec-opt native.cgroupdriver=systemd/" /usr/lib/systemd/system/docker.service
# Enable CRI for ContainerD
sed -i 's/^disabled_plugins = \["cri"\]$/disabled_plugins = \[\]/' /etc/containerd/config.toml
# Enable Mount Propagation
sed -i '/MountFlags=./d' /usr/lib/systemd/system/docker.service
sed -i 's/\[Service\]/\[Service\]\nMountFlags=shared\n/' /usr/lib/systemd/system/docker.service
# Prepare private registry
if [[ "$registry" != '' ]]
then
  echo -e "{\n  \"insecure-registries\": [\"${registry}\"],\n  \"registry-mirrors\": [\"http://${registry}\"]\n}" > /etc/docker/daemon.json
fi
systemctl daemon-reload
systemctl restart docker

systemctl daemon-reload
systemctl restart containerd.service

# Mount Probagation & NFS
mount --make-shared /
apt-get -qq install -y  nfs-common

echo -e "\n${BOLDGREEN}Installing Kubernetes...${ENDCOLOR}"
# Disble swap
swapoff -a
sed -i "s/^\/swap/#\/swap/" /etc/fstab
# Install k8s
apt-get -qq install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get -qq update
apt-get -qq install -y kubelet=${KUBEVER} kubeadm=${KUBEVER} kubectl=${KUBEVER}
apt-mark hold kubelet kubeadm kubectl

# If you are not creating a new cluster, we can stop here
# Just show some instructions for joining an existing cluster
if [[ "$newcluster" != 'y' ]]
then
  echo -e "\n${BOLDGREEN}Setup is complete. Now you can join the cluster${ENDCOLOR}"
  echo -e "\n${BOLDWHITE}To get the join command, run this command on control plane:${ENDCOLOR}"
  echo -e "sudo kubeadm token create --print-join-command"
  echo -e "\n${BOLDWHITE}If this is going to be a control plane node, first, run this command on an existing control plane node:${ENDCOLOR}"
  echo -e "sudo kubeadm init phase upload-certs --upload-certs"
  echo -e "\n${BOLDWHITE}Get the key from the previous command and run this command on a control plane node:${ENDCOLOR}"
  echo -e "sudo kubeadm token create --print-join-command --certificate-key ${BOLDRED}{KEY}${ENDCOLOR}"
  echo -e "\n${BOLDWHITE}Get the join command and run it here${ENDCOLOR}"
  echo -e "\n${BOLDWHITE}If this is a master plane and you want to run work load on this node, you have to untaint the node from master taint${ENDCOLOR}"
  echo -e "kubectl taint node ${hostname} node-role.kubernetes.io/master-"
  echo -e "Edit /etc/cni/net.d/10-weave.conflist and make \"cniVersion\": \"0.2.0\""
  exit
fi

echo -e "\n${BOLDGREEN}Creating Kubernetes Cluster...${ENDCOLOR}"
kubeadm init --control-plane-endpoint $ip # --pod-network-cidr=10.17.0.0/16 --service-cidr=10.18.0.0/16

export KUBECONFIG=/etc/kubernetes/admin.conf

# Enable workload on master
kubectl taint node ${hostname} node-role.kubernetes.io/master-

# Pod Network Add-On
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended.yaml

# Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p='{"spec":{"externalTrafficPolicy":"Cluster"}}'
kubectl patch deployment ingress-nginx-controller -n ingress-nginx -p='{"spec":{"replicas":2}}'

# Cert-Manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml

# MetalLB
#kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system
#kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
#curl https://raw.githubusercontent.com/TwistedHardware/k8s/main/address-pool.yaml | sed -e "s/103.101.44.17\/32/${lb}/" | kubectl apply -f - -n metallb-system
#kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
# set the load balancer to use default address pool
#kubectl patch services ingress-nginx-controller -n ingress-nginx -p='{"metadata":{"annotations":{"metallb.universe.tf/address-pool":"default"}}}'

# Longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.2.3/deploy/longhorn.yaml

# Install registry
#kubectl apply -f https://raw.githubusercontent.com/TwistedHardware/k8s/main/registry-pvc.yaml
#kubectl apply -f https://raw.githubusercontent.com/TwistedHardware/k8s/main/registry-deployment.yaml
#kubectl apply -f https://raw.githubusercontent.com/TwistedHardware/k8s/main/registry-service.yaml
#kubectl apply -f https://raw.githubusercontent.com/TwistedHardware/k8s/main/registry-ingress.yaml

# create a user for dashboard
kubectl apply -f https://raw.githubusercontent.com/TwistedHardware/k8s/main/dashboard-adminuser.yaml
#token=$(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}")
#echo -e "\n Your token for Kubernetes Dashboard:\n\n"
#echo $token
#echo -e "\n\n"

# Untaint master
echo -e "If you want to run this as a standalone node, or you want to run work load on this node, you have to untaint the node from master taint"
echo -e "kubectl taint node ${hostname} node-role.kubernetes.io/master-"
