#!/bin/bash

RED="31"
GREEN="32"
BOLDGREEN="\e[1;${GREEN}m"
BOLDRED="\e[1;${RED}m"
ITALICRED="\e[3;${RED}m"
ENDCOLOR="\e[0m"

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
echo -e "    │                            │"
echo -e "    │ This will setup your node  │"
echo -e "    │ to use in as a kubernetes  │"
echo -e "    │ IntegraNet cluster.        │"
echo -e "    │                            │"
echo -e "    └────────────────────────────┘"
echo -e ""
echo -e ""

read -p "Enter hostname [${hostname}]: " hostname

while ! [[ "$masterplane" =~ ^(y|n)$ ]] 
do
    read -p "Is this a master plane node? [y/n]: " masterplane
done 

# find the right IP for the cluster
read -a ipList <<< $(hostname -I)


for i in "${!ipList[@]}"
do
  index=$(($i+1));
  echo -e "${index}: ${ipList[$i]}"
   # do whatever on "$i" here
done
read -p "What is the IP that will used to access this cluster? [1]: " ip

if [[ "$ip" == '' ]]
then
  ip=1
fi

ip=$((ip-1))
ip="${ipList[$ip]}"



echo Your Hostname: $hostname
echo Masterplace: $masterplane
echo "ClusterIP: $ip"

if [[ "$hostname" != '' ]]
then
  echo $hostname > /etc/hostname
fi

echo "Installing Docker..."
sudo apt-get -qq install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.lis>
sudo apt-get install docker-ce docker-ce-cli containerd.io
# change cgroup of docker to systemd, then restart docker
sed -i 's/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ --containerd=\/run\/containerd\/containerd.sock/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ --containerd=\/run\/containerd\/containerd.sock --exec-opt nat>
sudo systemctl daemon-reload
systemctl restart docker

echo "Installing Kubernetes..."
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get -qq update
sudo apt-get -qq install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Creating Kubernetes Cluster"
kubeadm init --control-plane-endpoint $ip 
