# Script to deploy pods on kubernetes (App + Prometheus)
# Prometheus pods
echo "Deploy Prometheus..."
# TODO Arthur + Laure (helm déjà installé sur la workstation)
echo "Done.\n"

# App pods
echo "Deploy App..."
kubectl apply -f kubectl
echo "Done.\n"