#!/bin/bash
read -p "Enter AKS ResourceGroup Name: " rgName
read -p "Enter AKS Cluster Name: " aksName
az aks get-credentials --resource-group $rgName --name $aksName
helm init --upgrade --service-account tiller
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/