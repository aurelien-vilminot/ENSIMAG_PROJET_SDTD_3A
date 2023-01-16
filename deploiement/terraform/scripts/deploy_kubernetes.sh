# Script to deploy pods on kubernetes (App + Prometheus)
readonly username="kubespray"

# Install kube prometheus stack
echo "Deploy Prometheus..."
kubectl create ns monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm -n monitoring install kube-prometheus-stack prometheus-community/kube-prometheus-stack

# Wait for prometheus to be ready the NodePort
# kubectl -n monitoring wait --for=condition=Running pod/prometheus-kube-prometheus-stack-prometheus-0 --timeout=60s
sleep 60
kubectl patch svc kube-prometheus-stack-prometheus -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"nodePort": 32000, "port": 9090, "protocol": "TCP", "targetPort": 9090}]}}'

# Wait for grafana to be ready and configure the NodePort
sleep 60
kubectl patch svc kube-prometheus-stack-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"nodePort": 32001, "port": 80, "protocol": "TCP", "targetPort": 3000}]}}'
echo "Done.\n"

# App pods
echo "Deploy App..."
kubectl apply -f kubectl
echo "Done.\n"

echo "Everything is setup. Cluster and Apps are ready to use!"