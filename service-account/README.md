# Creatingly
## _Service Account_
In this section, we will do the following:
- Create a read-only user in Kubernetes that can access to Grafana namespace and perform port forwarding,

## Code
See content in this folder
```sh
service-account$ tree
.
├── README.md
├── ca.crt
├── grafana-cluster-role.yaml
├── grafana-role-binding.yaml
├── grafana-service-account.yaml
└── read_only_kubeconfig
```
## Create service account

Create a service account in the namwespace where Grafan is deployed (_I'm installing it in default namespace_)

```sh
apiVersion: v1
kind: Namespace
metadata:
  name: default

apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana-service-account 
  namespace: default

---
apiVersion: v1
kind: Secret
metadata:
  name: grafana-service-account-token
  namespace: default 
  annotations:
    kubernetes.io/service-account.name: "grafana-service-account"
type: kubernetes.io/service-account-token
```
Apply it
```sh
kubectl -f grafana-service-account.yaml
```
## Create a cluster role
```sh
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: grafana-cluster-role
rules:
  - apiGroups: [""]
    resources: ["pods", "services"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["pods/portforward"]
    verbs: ["create"]
```
Above rules are limited to read access to pods/services in the Grafana namespace. We have to grant the service account create permission so that it can do port-forwarding. (_Grafana service is deployed with ClusterIP_)

Apply it
```sh
kubectl apply -f grafana-cluster-role.yaml
```
## Create role binding
```sh
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: grafana--cluster-role-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: grafana-service-account
  namespace: default
roleRef:
  kind: ClusterRole
  name: grafana-cluster-role
  apiGroup: rbac.authorization.k8s.io
```
Apply it
```sh
kubectl apply -f grafana-role-binding
```
## Prepare kubeconfig
Checkout this sample kubeconfig
```sh
apiVersion: v1
clusters:
- cluster:
    certificate-authority: ./ca.crt
    server: <api-server-url>
  name: cluster-flowing-bedbug
contexts:
- context:
    cluster: cluster-flowing-bedbug
    user: grafana-service-account
    namespace: default
  name: cluster-flowing-bedbug
current-context: cluster-flowing-bedbug
kind: Config
preferences: {}
users:
- name: grafana-service-account
  user:
    token: <grafana-service-account-token>
```
### Some notes
_ca.crt_ is the original ca when you create the cluster. Get it by this command
```sh
kubectl get secret grafana-service-account-token -n default -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt
```
_api-server-url_ is the URL of API server. You can get it using command
```sh
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```
_grafana-service-account-token_ is the user token to authenticate with the API. You can get it using this command
```sh
kubectl get secret grafana-service-account-token -n default -o=jsonpath='{.data.token}' | base64 --decode
```
## Testing
Export the kubeconfig
```sh
export KUBECONFIG=read_only_kubeconfig
```
Make sure the user can't access resources in namespaces not specified
```sh
$ kubectl get nodes
Error from server (Forbidden): nodes is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "nodes" in API group "" at the cluster scope
$ 
$ kubectl get all -n kube-system
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "pods" in API group "" in the namespace "kube-system"
Error from server (Forbidden): replicationcontrollers is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "replicationcontrollers" in API group "" in the namespace "kube-system"
Error from server (Forbidden): services is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "services" in API group "" in the namespace "kube-system"
Error from server (Forbidden): daemonsets.apps is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "daemonsets" in API group "apps" in the namespace "kube-system"
Error from server (Forbidden): deployments.apps is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "deployments" in API group "apps" in the namespace "kube-system"
Error from server (Forbidden): replicasets.apps is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "replicasets" in API group "apps" in the namespace "kube-system"
Error from server (Forbidden): statefulsets.apps is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "statefulsets" in API group "apps" in the namespace "kube-system"
Error from server (Forbidden): horizontalpodautoscalers.autoscaling is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "horizontalpodautoscalers" in API group "autoscaling" in the namespace "kube-system"
Error from server (Forbidden): cronjobs.batch is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "cronjobs" in API group "batch" in the namespace "kube-system"
Error from server (Forbidden): jobs.batch is forbidden: User "system:serviceaccount:default:grafana-service-account" cannot list resource "jobs" in API group "batch" in the namespace "kube-system"
$ 
```
Make sure the user can access the pods/services in the namespace specified
```sh
$ kubectl get pods -n default
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-monitoring-stack-kube-prom-alertmanager-0   2/2     Running   0          11h
monitoring-stack-grafana-6d75f475c8-kbwht                3/3     Running   0          11h
monitoring-stack-kube-prom-operator-76f6567bd8-kfglk     1/1     Running   0          11h
monitoring-stack-kube-state-metrics-f6f88846-qq2j2       1/1     Running   0          11h
monitoring-stack-prometheus-node-exporter-2q67j          1/1     Running   0          11h
monitoring-stack-prometheus-node-exporter-8md47          1/1     Running   0          11h
monitoring-stack-prometheus-node-exporter-mtt84          1/1     Running   0          11h
prometheus-monitoring-stack-kube-prom-prometheus-0       2/2     Running   0          11h
$ 
$ kubectl get svc -n default
NAME                                        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
alertmanager-operated                       ClusterIP   None           <none>        9093/TCP,9094/TCP,9094/UDP   11h
kubernetes                                  ClusterIP   10.0.0.1       <none>        443/TCP                      13h
monitoring-stack-grafana                    ClusterIP   10.0.46.70     <none>        80/TCP                       11h
monitoring-stack-kube-prom-alertmanager     ClusterIP   10.0.210.252   <none>        9093/TCP,8080/TCP            11h
monitoring-stack-kube-prom-operator         ClusterIP   10.0.81.218    <none>        443/TCP                      11h
monitoring-stack-kube-prom-prometheus       ClusterIP   10.0.221.205   <none>        9090/TCP,8080/TCP            11h
monitoring-stack-kube-state-metrics         ClusterIP   10.0.202.178   <none>        8080/TCP                     11h
monitoring-stack-prometheus-node-exporter   ClusterIP   10.0.146.180   <none>        9100/TCP                     11h
prometheus-operated                         ClusterIP   None           <none>        9090/TCP                     11h
```
Now do the port forwarding to Grafana service
```sh
$ kubectl port-forward svc/monitoring-stack-grafana 8080:80
Forwarding from 127.0.0.1:8080 -> 3000
Forwarding from [::1]:8080 -> 3000
```
Open URL http://localhost:8080 and login to Grafa (_You also need a login user on Grafana_)