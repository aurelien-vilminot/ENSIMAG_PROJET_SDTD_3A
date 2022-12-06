# Script to launch all things needed for the kubenertes cluster
if [[ $# -ne 1 ]]
then
  echo "Usage: start.sh <id-project>"
  exit
fi

# Set project and enable needed services
export GOOGLE_CLOUD_PROJECT="$1"
gcloud config set project $GOOGLE_CLOUD_PROJECT
gcloud services enable compute.googleapis.com

# Generate ssh-keys
bash scripts/ssh-generate-keys.sh

# Launch terraform
terraform init
terraform apply -auto-approve
