#!/bin/bash
cd "$(dirname "$(realpath "$0")")";
helm install coreos/prometheus-operator --name prometheus-operator --namespace monitoring
helm install coreos/kube-prometheus --name kube-prometheus --namespace monitoring --networkPolicy.enabled=true
kubectl apply -f prometheus-networkpolicy.yaml
kubectl patch deployment -f kube-dns-metrics-patch.yaml