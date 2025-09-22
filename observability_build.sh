# enable promethues stack

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace observability --create-namespace

#  use custom values for adding loki datasource
helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack -n observability \
  -f helm/prom-values.yaml \
  # --reuse-values


# Rollback to previous working version
helm rollback kube-prometheus -n observability

# Then upgrade with the corrected values
helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack -n observability \
  -f helm/prom-values.yaml

# create context
kubectl config set-context observability \
  --cluster=kind-kind \
  --user=kind-kind \
  --namespace=observability

# patch or port-forward

kubectl patch svc kube-prometheus-grafana -n observability \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 3000, "nodePort": 31000}]}}'

kubectl patch svc kube-prometheus-kube-prome-prometheus -n observability \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 9090, "targetPort": 9090, "nodePort": 31071}]}}'  


kubectl port-forward svc/kube-prometheus-grafana -n observability 3000:80
Login with admin/prom-operator

# revert back to clusterip
kubectl patch svc kube-prometheus-grafana -n observability \
  -p '{"spec": {"type": "ClusterIP", "ports": [{"port": 80, "targetPort": 3000}]}}'


# check alert rules with global search expression
kubectl get prometheusrule -n observability -o yaml | grep -A 10 -B 10 "AlertmanagerFailedReload"


# enable logging

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki grafana/loki-stack --namespace observability \
  --set loki.isDefault=false \
  --set promtail.enabled=true \
  --set grafana.enabled=false \
  --set grafana.sidecar.datasources.enabled=false
  --create-namespace  # you need to manually change datastore isdefault to false

helm upgrade --install loki grafana/loki-stack --namespace observability -f helm/loki-values.yaml --reuse-values

helm install loki grafana/loki-stack --namespace observability -f helm/loki-values.yaml

helm uninstall loki --namespace observability

# enable tracing
helm install tempo grafana/tempo --namespace observability \
  --set tempo.timedb.enabled=true \
  --set tempo.search.enabled=true \
  --set metricsGenerator.enabled=true \
  --set tempo.tracing.otlp.http.enabled=true \
  --set tempo.tracing.otlp.grpc.enabled=true \
  --set service.otlpHttp.type=NodePort \
  --set service.otlpGrpc.type=NodePort \
  --set service.tempo.type=NodePort \
  --create-namespace

# Manually add Tempo datasource in Grafana UI:
# URL: http://tempo.observability.svc.cluster.local:3200
# Type: Tempo
# tempo.timedb.enabled=true - Enables the new time-based database (recommended)
# tempo.search.enabled=true - Enables trace search functionality
# metricsGenerator.enabled=true - Generates metrics from traces
# tempo.tracing.otlp.http.enabled=true - Enables OTLP HTTP receiver
# tempo.tracing.otlp.grpc.enabled=true - Enables OTLP gRPC receiver

# or use helm to install all in one: helm list -n observability
helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack -n observability \
  --set grafana.additionalDataSources[3].name=Tempo \
  --set grafana.additionalDataSources[3].type=tempo \
  --set grafana.additionalDataSources[3].url=http://tempo:3200 \
  --set grafana.additionalDataSources[3].access=proxy \
  --set grafana.additionalDataSources[3].isDefault=false \
  --reuse-values

# install otel operator

# Add the OpenTelemetry Helm repository
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# Install the operator
helm install opentelemetry-operator open-telemetry/opentelemetry-operator \
  --namespace observability \
  --create-namespace

# install OpenTelemetry Collector

kubectl apply -f otel-collector.yaml

# or use helm

helm install otel-collector open-telemetry/opentelemetry-collector \
  -n observability -f otel-values.yaml


# restart deployment in case of failure

kubectl apply -f otel-collector.yaml
kubectl rollout restart deploy otel-collector -n observability

# check otel deployment log
kubectl logs -n observability -l app.kubernetes.io/name=opentelemetry-collector

# troubleshooting: restart deployment

kubectl rollout restart deployment kube-prometheus-grafana -n observability


# stop cluster

# Stop the cluster
kind stop --name your-cluster-name

# Start it again later
kind start --name your-cluster-name