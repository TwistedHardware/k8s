# This is how to setup extra masterplane nodes 

First, ssh into a working master and run this command.

```
sudo kubeadm init phase upload-certs --upload-certs
```

Copy the key and use it this command:

```
sudo kubeadm token create --print-join-command --certificate-key {KEY}
```

Copy the command you got from the previous step and ssh into the new node and run the command with `sudo`:

```
sudo kubeadm join {IP}:6443 --token XXX --discovery-token-ca-cert-hash sha256:XXX --control-plane --certificate-key XXX
```
