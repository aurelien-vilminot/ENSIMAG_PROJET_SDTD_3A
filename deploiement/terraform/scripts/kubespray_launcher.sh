# Script to setup and start kubernetes with kubespray
readonly username="kubespray"

# Wait all others VMs (controllers + workers)
# TODO : appeler la commande en commentaire dans le for avec les bons paramètres et faire les cas de sorties comme pour wait workstation VM
declare -a IPS=($(gcloud compute instances list --filter="tags.items=kubespray-network AND (tags.items=controller OR tags.items=worker)" --format="value(EXTERNAL_IP)"  | tr '\n' ' '))
echo "Waiting for all others VMs..."
while true
do
    sleep 5
    find=0
    for (( i=0; i<${#IPS[@]}; i++ )); do
        echo "$i=${IPS[$i]}"
        status=$(ssh -o "StrictHostKeyChecking no" $username@${IPS[$i]} command cat /var/log/syslog | grep -m 1 "startup-script exit status" | tr -d '\n' | tail -c 1)
        case $status in
            0) # When startup-script is a success
            ;;
            1) # When startup-script is a failure
            exit 1
            ;;
            *) # Startup-script isn't over
            find=1
            break
            ;;
        esac
    done

    if [ $find -eq 0 ];
    then
        break
    fi
done
echo "Done.\n"

# Wait workstation VM
echo "Waiting for workstation VM..."
while true
do
    sleep 5
    status=$(cat /var/log/syslog | grep -m 1 "startup-script exit status" | tr -d '\n' | tail -c 1)
    case $status in
        0) # When startup-script is a success
        break
        ;;
        1) # When startup-script is a failure
        exit 1
        ;;
        *) # Startup-script isn't over
        continue
        ;;
    esac
done
echo "Done.\n"

# Setup kubespray
echo "Starting setup..."
cp -rfp inventory/sample inventory/mycluster
declare -a IPS=($(gcloud compute instances list --filter="tags.items=kubespray-network AND (tags.items=controller OR tags.items=worker)" --format="value(EXTERNAL_IP)"  | tr '\n' ' '))
declare -a IPS_INTER=($(gcloud compute instances list --filter="tags.items=kubespray-network AND (tags.items=controller OR tags.items=worker)" --format="value(INTERNAL_IP)"  | tr '\n' ' '))
CONFIG_FILE=inventory/mycluster/hosts.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

# Remove access_ip + setup groups (controllers / workers)
# Get lists of controllers and workers
declare -a IPS_CONTROLLER=($(gcloud compute instances list --filter="tags.items=kubespray-network AND tags.items=controller" --format="value(EXTERNAL_IP)"  | tr '\n' ' '))
declare -a IPS_WORKER=($(gcloud compute instances list --filter="tags.items=kubespray-network AND tags.items=worker" --format="value(EXTERNAL_IP)"  | tr '\n' ' '))
number_controller=$(echo ${#IPS_CONTROLLER[@]})
number_worker=$(echo ${#IPS_WORKER[@]})

# Remove useless lines in hosts.yml
kube_plane_line=$(cat inventory/mycluster/hosts.yml | grep -n '.*kube_control_plane:.*' | head -n 1 | cut -d ':' -f 1)
etcd_line=$(cat inventory/mycluster/hosts.yml | grep -n '.*etcd:.*' | head -n 1 | cut -d ':' -f 1)
kube_plane_line=$(($kube_plane_line + 1))
etcd_line=$(($etcd_line - 1))
sed -i ''${kube_plane_line}','${etcd_line}'d;/access_ip/d' inventory/mycluster/hosts.yml

# Add correct lines in hosts.yml
touch tmp_hosts.yml
kube_plane_line=$(cat inventory/mycluster/hosts.yml | grep -n '.*kube_control_plane:.*' | head -n 1 | cut -d ':' -f 1)
head -n $kube_plane_line inventory/mycluster/hosts.yml > tmp_hosts.yml
echo -e "      hosts:" >> tmp_hosts.yml
for (( i=1; i<=${number_controller}; i++ ));
do
    echo -e "        node$i:" >> tmp_hosts.yml
done
echo -e "    kube_node:" >> tmp_hosts.yml
echo -e "      hosts:" >> tmp_hosts.yml
for (( i=${number_controller} + 1; i<=${number_controller} + ${number_worker}; i++ ));
do
    echo -e "        node$i:" >> tmp_hosts.yml
done
etcd_line=$(cat inventory/mycluster/hosts.yml | grep -n '.*etcd:.*' | head -n 1 | cut -d ':' -f 1)
tail --lines=+$etcd_line inventory/mycluster/hosts.yml >> tmp_hosts.yml
mv tmp_hosts.yml inventory/mycluster/hosts.yml

# Change ip from external to internal
for (( i=0; i<${#IPS[@]}; i++ ));
do
    sed -i "s/ip: ${IPS[i]}/ip: ${IPS_INTER[i]}/" inventory/mycluster/hosts.yml;
done

# Remote acccess setup
LINE_SUPP=$(cat inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml | grep -n 'supplementary' | cut -d ':' -f 1)
list_ip_controller=$(echo ${IPS_CONTROLLER[@]} | sed "s/ /, /g") 
sed -i $LINE_SUPP's/.*/supplementary_addresses_in_ssl_keys: ['${list_ip_controller}']/' inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
echo "Done.\n"

# Start
echo "Starting kubernetes cluster... It will take a while!\n"
ansible-playbook -i inventory/mycluster/hosts.yml -u $username -b -v --private-key=/root/.ssh/id_rsa cluster.yml
echo "Kubernetes cluster is started.\n"

# Get remote access
echo "Getting remote access..."
ip_controller=${IPS_CONTROLLER}
ssh -o "StrictHostKeyChecking no" $username@$ip_controller command "sudo chown -R ${username}:${username} /etc/kubernetes/admin.conf"
scp $username@$ip_controller:/etc/kubernetes/admin.conf kubespray-do.conf
sed -i -e "/.*server: https:.*/c\    server: https://${ip_controller}:6443" kubespray-do.conf

echo export KUBECONFIG=$PWD/kubespray-do.conf >> /root/.bashrc
source /root/.bashrc
echo "Done.\n"

# Deploy Script
bash deploy_kubernetes.sh
