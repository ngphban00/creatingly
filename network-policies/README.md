# Creatingly
## _Network Policies_
In this section, we will do the following:
- Create the __apps__ and __dbs__ namespaces in the Kubernetes cluster.
- Configure Calico network policies:
-- Restrict access to pods in the __apps__ namespace so that they are only accessible externally and not by other namespaces.
-- Allow pods in the __dbs__ namespace to be accessed only by pods in the __apps__ namespace.

## Pre-requisites
Make sure the lab setup has Calico configued

```sh
$ kubectl get all -n calico-system 
NAME                                           READY   STATUS    RESTARTS   AGE
pod/calico-kube-controllers-56db68586b-n69kq   1/1     Running   0          6h1m
pod/calico-node-68nnl                          1/1     Running   0          6h1m
pod/calico-node-vvgvp                          1/1     Running   0          6h1m
pod/calico-node-zjw4x                          1/1     Running   0          6h1m
pod/calico-typha-659dbf8f89-6d9p6              1/1     Running   0          6h1m
pod/calico-typha-659dbf8f89-hf86z              1/1     Running   0          6h1m
pod/csi-node-driver-qcx88                      2/2     Running   0          6h1m
pod/csi-node-driver-sbcrn                      2/2     Running   0          6h1m
pod/csi-node-driver-tcvzk                      2/2     Running   0          6h1m

NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/calico-kube-controllers-metrics   ClusterIP   None             <none>        9094/TCP   6h
service/calico-typha                      ClusterIP   10.105.216.184   <none>        5473/TCP   6h1m

NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/calico-node       3         3         3       3            3           kubernetes.io/os=linux   6h1m
daemonset.apps/csi-node-driver   3         3         3       3            3           kubernetes.io/os=linux   6h1m

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/calico-kube-controllers   1/1     1            1           6h1m
deployment.apps/calico-typha              2/2     2            2           6h1m

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/calico-kube-controllers-56db68586b   1         1         1       6h1m
replicaset.apps/calico-typha-659dbf8f89              2         2         2       6h1m
```

```sh
$ kubectl get all -n calico-apiserver 
NAME                                   READY   STATUS    RESTARTS   AGE
pod/calico-apiserver-884f5986f-dfl5p   1/1     Running   0          6h
pod/calico-apiserver-884f5986f-lhz5q   1/1     Running   0          6h

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/calico-api   ClusterIP   10.103.78.30   <none>        443/TCP   6h

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/calico-apiserver   2/2     2            2           6h

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/calico-apiserver-884f5986f   2         2         2       6h

```

## Create namespaces

Go over __network-policies__ folder
```sh
cd network-policies
```

Create __apps__ namespace first

```sh
kubectl create ns apps
```
```sh
$ kubectl describe ns apps 
Name:         apps
Labels:       kubernetes.io/metadata.name=apps
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.

```

and create __dbs__ namespace

```sh
kubectl create ns apps
```
```sh
$ kubectl describe ns dbs
Name:         dbs
Labels:       kubernetes.io/metadata.name=dbs
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.

```
## Network policies for apps namespace
### Deploy
Check out the policies for __apps__ namespace
```sh
# Allow external access 
# Deny access from other namespaces 

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-deny-internal
  namespace: apps
spec:
  podSelector: {}  # This applies to all pods in the apps namespace
  policyTypes:
  - Ingress
  ingress:
  # Allow traffic from external IPs (Internet)
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0
        except: [192.168.171.0/24]
```
With this policy, all pods in __apps__ namespace will accept incoming traffic from any IPs, except IPs from internal namespaces

Apply it
```sh
kubectl apply -f apps-allow-external-deny-internal.yaml 
```
```sh
$ kubectl -n apps describe networkpolicies allow-external-deny-internal 
Name:         allow-external-deny-internal
Namespace:    apps
Created on:   2024-08-30 14:00:03 +0700 +07
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    To Port: <any> (traffic allowed to all ports)
    From:
      IPBlock:
        CIDR: 0.0.0.0/0
        Except: 192.168.171.0/24
  Not affecting egress traffic
  Policy Types: Ingress
```
Note a few things about this network policies template:
- If we allow all external (public) access, we have to specify CIDR as 0.0.0.0/0.
- To deny access from internal namespaces, we have to exclude the pods' IP range (192.168.171.0/24 in our case)

### Use case
We will create a web service in __apps_ namespace, then test access to it from another namespace or from outside the cluster.
Do this
```sh
$ kubectl run web --namespace=apps --image=nginx --expose --port=80
service/web created
pod/web created
```
#### Test from a pod in another namespace
Do this
```sh
$ kubectl run test-$RANDOM --namespace=dbs --rm -i -t --image=alpine -- sh
If you don't see a command prompt, try pressing enter.
/ # ip a show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0@if31: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP qlen 1000
    link/ether b2:db:e2:4a:dc:96 brd ff:ff:ff:ff:ff:ff
    inet 192.168.171.25/32 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::b0db:e2ff:fe4a:dc96/64 scope link 
       valid_lft forever preferred_lft forever
/ # wget -qO- --timeout=3 http://web.apps
wget: download timed out
/ # 
```
#### Test from outside the cluster
We would need a Load Balancer to expose the service first. So let's create MetalLB
Install the MetalLB Helm chart
```sh
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install -n metallb-system metallb metallb/metallb
```

Then we will create the IP address pool that will be advertised by the MetalLB controller
```sh
kubectl apply -f ip_address_pool.yaml
```

Checkout the IP pool
```sh
$ kubectl get ipaddresspools.metallb.io -n metallb-system 
NAME          AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
public-pool   true          false             ["192.168.58.100-192.168.58.110"]
```

Now expose the nginx service (in namespace __apps__) publicly
```sh
kubectl -n apps expose service web --name public-web-access --type LoadBalancer
```

Now test from your local PC
```sh
$ kubectl get svc -n apps
NAME                TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)        AGE
public-web-access   LoadBalancer   10.107.93.216    192.168.58.100   80:32393/TCP   15s
web                 ClusterIP      10.105.211.110   <none>           80/TCP         29m
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
 kubectl -n dbs describe networkpolicies dbs-allow-apps-deny-all 
Name:         dbs-allow-apps-deny-all
Namespace:    dbs
Created on:   2024-08-30 16:20:06 +0700 +07
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

### Use case
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
$ kubectl get all -n dbs
NAME                         READY   STATUS    RESTARTS   AGE
pod/mysql-6666d46f58-5bdfp   1/1     Running   0          6s

NAME            TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/mysql   ClusterIP   None         <none>        3306/TCP   6s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mysql   1/1     1            1           6s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/mysql-6666d46f58   1         1         1       6s
```

Now test from __apps__ namespace
```sh
$ kubectl run test-$RANDOM --namespace=apps --rm -i -t --image=alpine -- sh
If you don't see a command prompt, try pressing enter.
/ # nc -vv mysql.dbs 3306
mysql.dbs (192.168.171.27:3306) open
J
5.6.51P,,6j7oM��rv{'J"hgK"cQmysql_native_password
^Csent 1, rcvd 78
punt!

/ # 
```

Test from another namespace
```sh
$ kubectl run test-$RANDOM --namespace=default --rm -i -t --image=alpine -- sh
If you don't see a command prompt, try pressing enter.
/ # nc -vv mysql.dbs 3306


nc: mysql.dbs (192.168.171.27:3306): Operation timed out
sent 0, rcvd 0
/ # 
```