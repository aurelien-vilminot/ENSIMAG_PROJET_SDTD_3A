# Script to deploy pods on kubernetes (App + Prometheus)
readonly username="kubespray"

# App pods
echo "Deploy App..."
kubectl apply -f kubectl
echo "Done.\n"

# Set the kafka-stats IP in the values.yaml file
kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=60s
export SCRAPEIP="$(kubectl get pods -o=wide | grep kafka-stats | tr -s ' ' | cut -d ' ' -f 6)"
sed -i "s/REPLACEME/$SCRAPEIP/g" values.yaml

# Install kube prometheus stack
echo "Deploy Prometheus..."
kubectl create ns monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm -n monitoring install kube-prometheus-stack prometheus-community/kube-prometheus-stack -f values.yaml

# Configure Prometheus NodePort
kubectl -n monitoring wait --for=condition=Ready pod/prometheus-kube-prometheus-stack-prometheus-0 --timeout=30s
kubectl patch svc kube-prometheus-stack-prometheus -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"nodePort": 32000, "port": 9090, "protocol": "TCP", "targetPort": 9090}]}}'

# Configure Grafana NodePort
kubectl patch svc kube-prometheus-stack-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"nodePort": 32001, "port": 80, "protocol": "TCP", "targetPort": 3000}]}}'

# Configure Alertmanager NodePort
kubectl patch svc kube-prometheus-stack-alertmanager -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"nodePort": 32002, "port": 9093, "protocol": "TCP", "targetPort": 9093}]}}'

echo "Done.\n"

echo "Everything is setup. Cluster and Apps are ready to use!"