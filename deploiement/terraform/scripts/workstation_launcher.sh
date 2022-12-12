# Change to restart automically deamons services
sudo sed -i "/.*nrconf{restart}.*/c\$nrconf{restart} = 'a';" /etc/needrestart/needrestart.conf;

# Update environment
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y;

# Install needed tools
sudo apt-get install -y git python3-pip

# Connect as root + ssh
sudo su
mv /home/kubespray/.ssh/id_rsa /root/.ssh/

# Install kubespray to root directory
cd /root
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout 09748e80e936e0479314d5a5a120a3c4bd321ffa
mv /home/kubespray/kubespray_launcher.sh /root/kubespray/
mv /home/kubespray/kubectl /root/kubespray
mv /home/kubespray/deploy_kubernetes.sh /root/kubespray/
pip3 install -r requirements.txt

# Install kubernetes to use at remote
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Helm
sudo apt-get update
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install -y apt-transport-https
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

# Kubespray Launcher
cd /root/kubespray
bash kubespray_launcher.sh
