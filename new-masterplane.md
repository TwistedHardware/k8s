# This is how to setup extra masterplane nodes 

First, ssh into a working master and run this command. Don't forget to replace `{USERNAME}` with the username from the new node.

```
sudo scp -r /etc/kubernetes/pki {USERNAME}@192.168.0.201:/home/{USERNAME}/
```

Now ssh into the new node and run this:

```
sudo mv pki/ /etc/kubernetes/
sudo chown root:root /etc/kubernetes/pki/
```

Now you can join the the cluter from the node as a masterplane.
