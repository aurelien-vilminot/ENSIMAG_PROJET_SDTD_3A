# Change to restart automically deamons services
sudo sed -i "/.*nrconf{restart}.*/c\$nrconf{restart} = 'a';" /etc/needrestart/needrestart.conf;

# Update environment
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y;

# Install needed tools
sudo apt-get install -y git python3-pip;

# Connect as root + ssh
sudo su;
mv /home/kubespray/.ssh/id_rsa /root/.ssh/

# Install kubespray to root directory
cd /root || exit;
git clone https://github.com/kubernetes-sigs/kubespray.git;
cd kubespray || exit
mv /home/kubespray/kubespray_launcher.sh /root/kubespray/
pip3 install -r requirements.txt;

# Install kubernetes to use at remote
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
