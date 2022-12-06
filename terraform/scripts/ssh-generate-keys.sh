# Generate ssh-keys for kubespray user
rm -f id_rsa
rm -f id_rsa.pub
ssh-keygen -q -C kubespray -f id_rsa -N ""
