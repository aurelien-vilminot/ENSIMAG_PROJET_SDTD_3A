# Change to restart automically deamons services
sudo sed -i "/.*nrconf{restart}.*/c\$nrconf{restart} = 'a';" /etc/needrestart/needrestart.conf;

# Update environment
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y;

# Install needed tools
sudo apt-get install -y git python3-pip;

# Install kubespray to root directory
sudo su;
cd /root;
wget https://raw.githubusercontent.com/kubernetes-sigs/kubespray/09748e80e936e0479314d5a5a120a3c4bd321ffa/requirements.txt
wget "https://raw.githubusercontent.com/kubernetes-sigs/kubespray/09748e80e936e0479314d5a5a120a3c4bd321ffa/$(cat requirements.txt)" -O install_requirements.txt

pip3 install -r install_requirements.txt;
