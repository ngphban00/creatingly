# Creatingly
## _Network Policies_
In this section, we will do the following:
- Create the __apps__ and __dbs__ namespaces in the Kubernetes cluster.
- Configure Calico network policies:
-- Restrict access to pods in the __apps__ namespace so that they are only accessible externally and not by other namespaces.
-- Allow pods in the __dbs__ namespace to be accessed only by pods in the __apps__ namespace.

## Pre-requisites
### Calico
Make sure the lab setup has Calico configued

```sh
 kubectl get all -n calico-system 
NAME                                          READY   STATUS    RESTARTS   AGE
pod/calico-kube-controllers-bb647c4f4-d4hb5   1/1     Running   0          24m
pod/calico-node-4zmp7                         1/1     Running   0          24m
pod/calico-node-gqnj2                         1/1     Running   0          24m
pod/calico-node-l8zpz                         1/1     Running   0          24m
pod/calico-node-n6smm                         1/1     Running   0          24m
pod/calico-typha-5b484996d7-767n6             1/1     Running   0          24m
pod/calico-typha-5b484996d7-bztv5             1/1     Running   0          24m
pod/csi-node-driver-6qstd                     2/2     Running   0          24m
pod/csi-node-driver-k6w94                     2/2     Running   0          24m
pod/csi-node-driver-tcrvg                     2/2     Running   0          24m
pod/csi-node-driver-xz6dr                     2/2     Running   0          24m

NAME                                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/calico-kube-controllers-metrics   ClusterIP   None           <none>        9094/TCP   22m
service/calico-typha                      ClusterIP   10.108.72.55   <none>        5473/TCP   24m

NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/calico-node       4         4         4       4            4           kubernetes.io/os=linux   24m
daemonset.apps/csi-node-driver   4         4         4       4            4           kubernetes.io/os=linux   24m

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/calico-kube-controllers   1/1     1            1           24m
deployment.apps/calico-typha              2/2     2            2           24m

NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/calico-kube-controllers-bb647c4f4   1         1         1       24m
replicaset.apps/calico-typha-5b484996d7             2         2         2       24m
```

```sh
$ kubectl get all -n calico-apiserver 
NAME                                    READY   STATUS    RESTARTS   AGE
pod/calico-apiserver-69fb48d7b8-8l7h7   1/1     Running   0          22m
pod/calico-apiserver-69fb48d7b8-q44rh   1/1     Running   0          22m

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/calico-api   ClusterIP   10.110.97.19   <none>        443/TCP   22m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/calico-apiserver   2/2     2            2           22m

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/calico-apiserver-69fb48d7b8   2         2         2       22m
```
### MetalLB
We would also need a Load Balancer to publicly expose a service. So let's create MetalLB
Install the MetalLB Helm chart
```sh
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install -n metallb-system metallb metallb/metallb --create-namespace
```

Then we will create the IP address pool that will be advertised by the MetalLB controller
```sh
kubectl apply -f ip-address-pool.yaml
```

Checkout the IP pool
```sh
$ kubectl get ipaddresspools.metallb.io -n metallb-system 
NAME          AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
public-pool   true          false             ["192.168.58.100-192.168.58.110"]
```

## Create namespaces

Create __apps__ and __dbs__ namespaces first

```sh
kubectl create ns apps
kubectl create ns dbs
```

Go over __network-policies__ folder
```sh
cd network-policies
```

## Network policies for apps namespace
### Deploy
```sh
kubectl apply -f allow-external-access-deny-other-namespaces.yaml
```
```sh
$ kubectl -n apps describe networkpolicies allow-external-access-deny-other-namespaces
Name:         allow-external-access-deny-other-namespaces
Namespace:    apps
Created on:   2024-08-31 14:50:22 +0700 +07
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    To Port: <any> (traffic allowed to all ports)
    From:
      IPBlock:
        CIDR: 0.0.0.0/0
        Except: 172.16.0.0/16
  Not affecting egress traffic
  Policy Types: Ingress
```
Note the Pod's IP blocks are 172.16.0.0/16

### Testing 
We will create a web service in __apps_ namespace, then test access to it from another namespace or from outside the cluster.
Do this
```sh
kubectl run web --namespace=apps --image=nginx --expose --port=80
```
#### Test from a pod in another namespace
```sh
$ kubectl run test-$RANDOM --namespace=dbs --rm -i -t --image=alpine -- sh
If you don't see a command prompt, try pressing enter.
/ # wget -qO- --timeout=3 http://web.apps
wget: download timed out
/ # 
```
#### Test from outside the cluster
Now expose the nginx service (in namespace __apps__) publicly
```sh
kubectl -n apps expose service web --name public-web-access --type LoadBalancer
```

Now test from your local PC
```sh
$ kubectl get svc -n apps
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
public-web-access   LoadBalancer   10.96.161.150   192.168.58.100   80:31938/TCP   64m
web                 ClusterIP      10.99.185.230   <none>           80/TCP         142m
```
```sh
$ curl http://192.168.58.100
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

#### Test within the same namespace
```sh
$ kubectl run test-$RANDOM --namespace=apps --rm -i -t --image=alpine -- sh
If you don't see a command prompt, try pressing enter.
/ # 
/ # 
/ # wget -qO- --timeout=2 http://web
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
/ # 
```

## Network policy for dbs namespace
Check it out
```sh
# Allow access only from apps namespace
# Deny other access 

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: dbs-allow-apps-deny-all
  namespace: dbs
spec:
  podSelector: {}  # This applies to all pods in the dbs namespace
  policyTypes:
  - Ingress
  ingress:
  # Allow traffic from nmespace apps
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: apps
```
### Deploy
Apply it
```sh
kubectl apply -f dbs-allow-apps-deny-all.yaml
```
```sh
$ kubectl -n dbs describe networkpolicies dbs-allow-apps-deny-all
Name:         dbs-allow-apps-deny-all
Namespace:    dbs
Created on:   2024-08-31 15:00:48 +0700 +07
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    To Port: <any> (traffic allowed to all ports)
    From:
      NamespaceSelector: kubernetes.io/metadata.name=apps
  Not affecting egress traffic
  Policy Types: Ingress
```

### Testing
We will deploy a MySQL server in __dbs__ namespace, then try to access from __apps__ namespce or another namespace
To deploy MySQL server on __dbs__ namespace, do this
```sh
$ kubectl -n dbs apply -f https://k8s.io/examples/application/mysql/mysql-pv.yaml
persistentvolume/mysql-pv-volume unchanged
persistentvolumeclaim/mysql-pv-claim created
$ kubectl -n dbs apply -f https://k8s.io/examples/application/mysql/mysql-deployment.yaml
service/mysql created
deployment.apps/mysql created
```

```sh
NAME                         READY   STATUS    RESTARTS   AGE
pod/mysql-6666d46f58-r8k5q   1/1     Running   0          33s

NAME            TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/mysql   ClusterIP   None         <none>        3306/TCP   33s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mysql   1/1     1            1           33s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/mysql-6666d46f58   1         1         1       33s
```

Now test from __apps__ namespace
```sh
$ kubectl run test-$RANDOM --namespace=apps --rm -i -t --image=alpine -- sh
If you don't see a command prompt, try pressing enter.
/ # nc -vv mysql.dbs 3306
mysql.dbs (172.16.37.210:3306) open
J
5.6.51B}q?'BWl▒>0suqW?rD<@kmysql_native_password
^Csent 1, rcvd 78
punt!

/ #
```

Test from another namespace
```sh
$ kubectl run test-$RANDOM --namespace=default --rm -i -t --image=alpine -- sh
If you don't see a command prompt, try pressing enter.
/ # nc -vv mysql.dbs 3306


nc: mysql.dbs (172.16.37.210:3306): Operation timed out
sent 0, rcvd 0
/ # 
```

## Clean up
```sh
kubectl -n apps delete svc web public-web-access
kubectl -n apps delete pod web
kubectl -n dbs delete -f https://k8s.io/examples/application/mysql/mysql-deployment.yaml
kubectl -n dbs delete -f https://k8s.io/examples/application/mysql/mysql-pv.yaml
```
