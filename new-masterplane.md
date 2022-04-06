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

## Troubleshooting:

If you get an error during `[check-etcd]` that looks like this:

```
error execution phase check-etcd: etcd cluster is not healthy: failed to dial endpoint https://192.168.151.75:2379 with maintenance client: context deadline exceeded
To see the stack of this error, execute with --v=5 or higher
```

**IMPORTANT:** Make sure that the IP in the error belongs to an etcd node that is not active anymore or not active yet.

First Remove the dead etcd node: from an active control plane/etcd node ron this code:

```
sudo -i
ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key member list
ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key member remove <node_id>
```


Second, reset the node:

```
sudo kubeadm reset
```

Then clear CLI and k8s config

```
sudo rm -rf /etc/cni/net.d
rm $HOME/.kube/config
```

Reboot the node

Join again, it should work now. If not, use `--v=5` to debug the error further.
