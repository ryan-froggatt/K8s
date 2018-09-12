#!/bin/bash
kubectl create serviceaccount ans -n kube-system
kubectl create clusterrolebinding ans -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:ans
kubectl get secret -n kube-system $(kubectl get serviceaccount ans -n kube-system -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode