# k8s

On new nodes, run this command:

```
wget -q https://raw.githubusercontent.com/TwistedHardware/k8s/main/setup.sh; chmod +x setup.sh; ./setup.sh; rm setup.sh
```

NOTE: If you are creating a new cluster, There will be a token on the screen at the end of the setup. Save the generated token somewhere safe.


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

To see the dashboard, run this command (make sure you [configured](#configure-kubectl) `kubectl` on your PC):

```
kubectl proxy
```

Then open the link:

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

If you don't have the token, ssh into a control plane node and run this command:

```
echo $(kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}")
```
