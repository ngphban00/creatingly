# Creatingly
## _Lab setup_


In this lab, we will create a Kubernetes cluster hvaing 3 nodes (1 master, 2 workers). We will create those nodes using vagrant, then create the cluster using Ansible.

## Pre-requisites
We would need a PC/laptop having some configurations as below

### Hardware
- Intel Core i7
- Memory 32 GB
- Hard disk 1 TB

### Software
- OS Ubuntu 24.04 LTS
- Vagrant 2.4.1
- Virtualbox 7.0
- Kubectl 1.30.4
- Helm 3.15.4
- Export documents as Markdown, HTML and PDF

## Installation

Check out this repo

```sh
https://github.com/ngphban00/creatingly.git
cd creatingly
```

Create VM nodes...
```sh
cd lab-setup
vagrant up
```

Deploy Ansible playbooks
```sh
ansible-playbook -i inventory/vagrant.hosts playbooks/ansible-playbook.yaml
```

Wait until the deployment finishes. Then login to the master node
```sh
vagrant ssh master
```

Check Kubernetes node status
```sh
kubectl get nodes
```

You should wait for a while before all nodes come to Ready status
```sh
NAME        STATUS   ROLES           AGE   VERSION
master      Ready    control-plane   72m   v1.30.4
worker-01   Ready    <none>          72m   v1.30.4
worker-02   Ready    <none>          72m   v1.30.4
```

Then copy the output of the kubeconfig on the master node
```sh
vagrant ssh master -c 'cat ~/.kube/config'
```

Overwrite the original __.kubeconfig__ file in the root of this repo with the output copied in previous step

Now check kube access from your local machine
```sh
export KUBECONFIG=.~/creatingly/.kubeconfig
kubectl get nodes
```

## Accomplishment

Below are what we can achieve in the lab. Follow README in each link in the table

| Task | README |
| ------ | ------ |
| Network Policies  | [network-policies/README.md][PlDb] |
| Service Account  | [service-account/README.md][PlGh] |
| Metrics Collection  | [metrics/README.md][PlGd] |
| Dashboard Creation/Access | [dashboard/README.md][PlOd] |
| Report | [report/README.md][PlMe] |
| Email Alert | [email-alert/README.md][PlGa] |
