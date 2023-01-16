# Script to deploy pods on kubernetes (App + Prometheus)
readonly username="kubespray"

# Prometheus pods
echo "Deploy Prometheus..."
kubectl create ns monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm -n monitoring install kube-prometheus-stack prometheus-community/kube-prometheus-stack
kubectl -n monitoring wait --for=condition=Running pod/prometheus-kube-prometheus-stack-prometheus-0 --timeout=60s
kubectl patch svc kube-prometheus-stack-prometheus -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"nodePort": 32000, "port": 9090, "protocol": "TCP", "targetPort": 9090}]}}'
echo "Done.\n"

# App pods
echo "Deploy App..."
kubectl apply -f kubectl
echo "Done.\n"

echo "Everything is setup. Cluster and Apps are ready to use!"