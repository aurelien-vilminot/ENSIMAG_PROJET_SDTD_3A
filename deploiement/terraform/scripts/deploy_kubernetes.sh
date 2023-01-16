# Script to deploy pods on kubernetes (App + Prometheus)
readonly username="kubespray"

# Prometheus pods
echo "Deploy Prometheus..."
# TODO Arthur + Laure (helm déjà installé sur la workstation)
kubectl create ns monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm -n monitoring install kube-prometheus-stack prometheus-community/kube-prometheus-stack
# TODO wait kube-prometheus-stack-prometheus pods running
sleep 60
# TODO fix port 32000
kubectl patch svc kube-prometheus-stack-prometheus -n monitoring -p '{"spec": {"type": "NodePort"}}'
echo "Done.\n"

# App pods
echo "Deploy App..."
kubectl apply -f kubectl
echo "Done.\n"

echo "Everything is setup. Cluster and Apps are ready to use!"