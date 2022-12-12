# Change to restart automically deamons services
sudo sed -i "/.*nrconf{restart}.*/c\$nrconf{restart} = 'a';" /etc/needrestart/needrestart.conf;

# Update environment
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y;

# Initialize Prometheus
sudo apt install -yq prometheus;