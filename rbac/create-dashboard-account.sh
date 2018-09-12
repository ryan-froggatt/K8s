#!/bin/bash
read -p "Input your service account username" username
kubectl create serviceaccount $username -n kube-system
kubectl create clusterrolebinding $username -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:ans
kubectl get secret -n kube-system $(kubectl get serviceaccount $username -n kube-system -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode