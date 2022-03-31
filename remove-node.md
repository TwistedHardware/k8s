# Remove a node from the Cluster

To remove a node from the cluster:

```
kubectl drain <node-name> --ignore-daemonsets
```

Then delete the node from the cluster:

```
kubectl delete node <node-name>
```

Finally, from the node itself, reset the node using this command:

```
kubeadm reset
```
