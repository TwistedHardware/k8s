# k8s

On new nodes, run this command:

```
wget -q https://raw.githubusercontent.com/TwistedHardware/k8s/main/setup.sh; chmod +x setup.sh; ./setup.sh; rm setup.sh
```

## Configure `kubectl`

To configure a `kubectl` on a remote PC to access the cluster, ssh into a control plane node and run this command:

```
sudo cat /etc/kubernetes/admin.conf
```

copy the output and save it on the remote PC in `~/.kube/config`

## Add control plane node

To add new control plane nodes:

[Read this](new-masterplane.md)

## Add worker node

To add a worker nodes:

[Read this](new-worker.md)

## Dashboard

To see the dashboard, run this command (make sure you configured `kubectl` on your PC):

```
kubectl proxy
```

Then open the link:

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
