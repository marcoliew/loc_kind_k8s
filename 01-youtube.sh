#!/bin/bash

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo update
# helm search repo open-telemetry --versions
# helm search repo jetstack --versions
OTEL_VERSION=0.93.1
CERTMANAGER_VERSION=v1.18.2

helm install \
cert-manager jetstack/cert-manager \
--namespace cert-manager \
--create-namespace \
--version $CERTMANAGER_VERSION \
--set crds.enabled=true \
--set startupapicheck.timeout="5m"

helm install opentelemetry-operator open-telemetry/opentelemetry-operator \
--namespace opentelemetry-operator-system \
--create-namespace \
--version $OTEL_VERSION \
--values=helm/01-optel-values.yaml

kubectl get pods -n cert-manager
kubectl get pods -n opentelemetry-operator-system

kubectl create namespace monitoring
kubectl apply -n monitoring -f manifest/01-collector-tracing.yaml

kubectl apply -f manifest/01-instrumentation.yaml

docker-compose --file 01-docker-compose.yaml build

kind load docker-image aimvector/service-mesh:videos-web-1.0.0 --name dev
kind load docker-image aimvector/service-mesh:playlists-api-1.0.0 --name dev
kind load docker-image aimvector/service-mesh:videos-api-1.0.0 --name dev

kubectl apply -f applications/playlists-api/
kubectl apply -f applications/playlists-api/
kubectl apply -f applications/playlists-db/
kubectl apply -f applications/videos-web/
kubectl apply -f applications/videos-db/
kubectl apply -f applications/videos-api/

kubectl port-forward svc/videos-web 80:80
kubectl port-forward svc/playlists-api 81:80

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
# helm search repo  grafana/tempo
TEMPO_VERSION=1.23.3

helm install tempo grafana/tempo \
    --create-namespace \
    --namespace grafana \
    --version $TEMPO_VERSION \
    --values helm/01-tempo.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm search repo prometheus-community --versions

PROMETHEUS_STACK_VERSION=77.5.0

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version $PROMETHEUS_STACK_VERSION \
  --namespace prometheus-operator-system \
  --create-namespace \
  --set prometheusOperator.enabled=true \
  --set prometheusOperator.nodeSelector."kubernetes\.io/os"=linux \
  --set prometheusOperator.fullnameOverride="prometheus-operator" \
  --set prometheusOperator.manageCrds=true \
  --set alertmanager.enabled=false \
  --set grafana.enabled=false \
  --set prometheus-node-exporter.enabled=false \
  --set nodeExporter.enabled=false \
  --set kubeStateMetrics.enabled=false \
  --set prometheus.enabled=false

  kubectl -n prometheus-operator-system get pods

  kubectl apply -n monitoring -f helm/01-prometheus.yaml


# helm search repo grafana/grafana

GRAFANA_VERSION=9.4.4

helm install grafana grafana/grafana \
  --namespace grafana \
  --version $GRAFANA_VERSION \
  --values helm/01-grafana.yaml