#!/bin/bash
read -p "Enter AKS ResourceGroup Name: " rgName
read -p "Enter AKS Cluster Name: " aksName
cd "$(dirname "$(realpath "$0")")";
az aks get-credentials --resource-group $rgName --name $aksName
kubectl apply -f helm-rbac.yaml
helm init --upgrade --service-account tiller
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/