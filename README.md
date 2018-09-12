# Kubernetes - Azure Container Service (AKS)

![logo](https://avatars1.githubusercontent.com/u/13629408?s=250)

This document covers deploying AKS and deploying configuration into Kubernetes and specifically into Azure Container Service (AKS) 
Each Deployment specified is not mandatory but adds additional functionality to Kubernetes Cluster.
This assumes you have the latest Azure CLI installed (2.0.21+)

# Set-up & Creation of AKS
This project contains an ARM template for deploying Azure Container Service (AKS), the below resources are deployed:
 - Azure Container Registry (ACR)
 - Virtual Network
 - AKS Cluster

[ARM Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates-cloud-consistency) are JSON files which describe resource deployments allowing them to be consistent and repeatable across environments.

Step 1 - Edit the parameters file [AKS.parameters.json](https://github.com/ryan-froggatt/K8s/blob/master/arm/AKS.parameters.json)  
Step 2 - Run the arm deployment script [AKS.deploy.json](https://github.com/ryan-froggatt/K8s/blob/master/arm/AKS.deploy.json) to deploy the resources and resource group if required.

---

# Deploying to Kubernetes
Once you have AKS deployed and are able to interact with it via `kubectl` you can start deploying kubernetes config to it

## Pre-requisites 
Before starting to deploy configuration into Kubernetes you will need to push your container images to the Azure Container Registry (ACR).

Refer to the main container guide for details
#### [:page_with_curl: Complete container guide](../docs/containers.md) 

Notes on Kubernetes deployment:
- When deploying to Kubernetes use of the `default` namespace is assumed.
- Kubernetes version 1.9+ is assumed, if you are using 1.8 or older the API version in the deployment YAML may require changing e.g. to `apiVersion: apps/v1beta1`. Older versions have not been tested.


## Deployment 1 - Helm Install (Easiest)
[Helm](https://helm.sh/) is a package manager for Kubernetes, and a Helm Chart has been created to deploy a number of resources. This means you can deploy Applications with a single command.

Step 1 - Install the Helm binary following the instructions at - https://github.com/helm/helm  
Step 2 - Run the [configure-helm.sh](https://github.com/ryan-froggatt/K8s/blob/master/helm/configure-helm.sh) script to initialise helm with a Kubernetes Service Account and add required helm repos.


## Deployment 2 - Create Dashboard Account
[RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) prevents the default AKS Dashboard account from accessing Kubernetes resources therefore a new service account should be created to view the Kubernetes Dashboard.

Step 1 - Run the script [create-dashboord-account.sh](https://github.com/ryan-froggatt/K8s/blob/master/rbac/create-dashboard-account.sh)  
Step 2 - Run the command - kubectl proxy  
Step 3 - Access the dashboard at - http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/login


## Deployment 3 - Deploy Certificate Manager
[CertManager](https://github.com/jetstack/cert-manager) is used to automatically provision and renew TLS certificates in your Kubenretes Cluster with LetsEncrypt.

Step 1 - Update the [cluster-issuer.yaml](https://github.com/ryan-froggatt/K8s/blob/master/cert-manager/cluster-issuer.yaml) & [certificates.yaml](https://github.com/ryan-froggatt/K8s/blob/master/cert-manager/certificates.yaml) files.  
Step 2 - Run command - kubectl apply -f cluster-issuer.yaml  
Step 3 - Run command - kubectl apply -f certificates.yaml


## Deployment 4 - Deploy Kube-Router & Network Policies
[Kube-Router](https://github.com/cloudnativelabs/kube-router) has a number of useful feartures within Kubernetes Networking, the primary reason for using Kube-Router is this project is the Network Policy Controller to enforce Network Security via Policies.

Step 1 - Run command - kubectl apply -f kube-router.deploy.yaml  
Step 2 - Run command - kubectl apply -f network-policies.yaml


## Deployment 5 - Deploy Cluster-Autoscaler
[Cluster-Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) is used to dynamically scale Kubernetes Worker Nodes based on resource consumption and pod resource allocation.

Step 1 - Run the [create-autoscaler-secret.sh](https://github.com/ryan-froggatt/K8s/blob/master/autoscaler/create-autoscaler-secret.sh) script and copy the output.  
Step 2 - Paste the output in to the Secret section within [aks-cluster-autoscaler.yaml](https://github.com/ryan-froggatt/K8s/blob/master/autoscaler/aks-cluster-autoscaler.yaml])  
Step 3 - Update the below section of [aks-cluster-autoscaler.yaml](https://github.com/ryan-froggatt/K8s/blob/master/autoscaler/aks-cluster-autoscaler.yaml]):  
Syntax:-  
--nodes=min_nodes:max_nodes:node_pool_name  
Example:-  
--nodes=3:10:agentpool  

Step 4 - Run the command - kubectl apply -f aks-cluster-autoscaler.yaml

## Deployment 6 - Deploy Ingress Controller & Rules
[External-Ingress](https://github.com/kubernetes/ingress-nginx) is used to route traffic from the internet via an External Azure Load Balancer to the relevant Kubernetes Microservices running inside the Cluster.

Step 1  - Run command - helm install stable/nginx-ingress --name my-nginx --set rbac.create=true


[Internal-Ingress](https://docs.microsoft.com/en-us/azure/aks/internal-lb) is used to route traffic from within the Azure vNet via an Internal Azure Load Balancer to the relevant Kubernetes Microservices running inside the Cluster.

Step 1 - Add the AKS Service Principal to the AKS Subnet with the Network Contributor role.  
Step 2 - Run command - helm install stable/nginx-ingress --namespace kube-system -f internal-loadbalancer.yaml


## Deployment 7 - Deploy MongoDB ReplicaSet and Backup
[MongoDB ReplicaSet](https://github.com/cvallance/mongo-k8s-sidecar) deploys a 3 node MongoDB ReplicaSet with persistent SSD storage which is backed by Azure Managed Disks.

Step 1 - Run command - kubectl apply -f mongodb.all.yaml


[MongoDB Backup](https://github.com/stefanprodan/mgob) deploys a Kubernetes Pod which takes MongoDB Backups and uploads to an Azure Storage Account.

Step 1 - Update the [mgob.cfg.yaml](https://github.com/ryan-froggatt/K8s/blob/master/deployments/mongo/mgob.cfg.yaml) & [mgob.deploy.yaml](https://github.com/ryan-froggatt/K8s/blob/master/deployments/mongo/mgob.deploy.yaml) files with the correct Storage Account and Database information.  
Step 2 - Run the command - kubectl apply -f mgob.cfg.yaml  
Step 3 - Run the command - kubectl apply -f mgob.deploy.yaml


## Deployment 8 - Deploy Frontend/API Applications
This Kubernetes Project utilises a docker containers for a web frontend and api that communicates with the backend MongoDB ReplicaSet. The deployments consist of a Kubernetes Service, Scaling Policy and Pod Deployment.

Step 1 - Run the command - kubectl apply -f api.svc.yaml  
Step 2 - Run the command - kubectl apply -f frontend.svc.yaml  
Step 3 - Run the command - kubectl apply -f api.deploy.yaml  
Step 4 - Run the command - kubectl apply -f frontend.deploy.yaml


## Deployment 9 - Deploy Prometheus/Grafana Monitoring
[Prometheus](https://github.com/prometheus/prometheus) a systems and service monitoring system. It collects metrics from configured targets at given intervals, evaluates rule expressions, displays the results, and can trigger alerts if some condition is observed to be true.

Step 1 - Run the script [deploy-prometheus.sh](https://github.com/ryan-froggatt/K8s/blob/master/prometheus/deploy-prometheus.sh)

## Deployment 10 - Run Kube-Hunter
[Kube-Hunter](https://github.com/aquasecurity/kube-hunter) hunts for security weaknesses in Kubernetes clusters.

Step 1 - Run the command - kubectl apply -f kube-hunter.job.yaml
