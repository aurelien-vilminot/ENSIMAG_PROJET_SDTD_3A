# Projet Système Distribué pour le Traitement de Données

Dépot contenant l'ensemble du projet système distribué pour le traitement de données.

## Équipe

Alexis BRUNO

Laure CERUTTI

Damien CLAUZON

Félix GANDER

Arthur SARRY

Aurélien VILMINOT

## Mise en place de l'environnement GCE

### Démarrage

1. Se rendre sur la console [Google Cloud](https://console.cloud.google.com)
2. Démarrer un projet si ce n'est pas déjà fait
3. Depuis le menu, se rendre dans _API et services_
4. Ajouter le service **Compute Engine API** en cliquant sur _Activer les API et les services_
5. Activer le _cloud shell_ via l'icône en haut à droite
6. Dans la console _cloud shell_ venant de s'ouvrir :
    ```
    git clone https://gitlab.ensimag.fr/brunoal/sytd
    cd ./deploiement/terraform
    chmod 777 ./scripts/env.sh
    bash start.sh <id_projet_gcloud>
    ```
7. Depuis le menu, se rendre dans *Compute Engine* > *Instances de VM*
8. Sur l'instance **workstation**, cliquer sur _SSH_
9. Dans la nouvelle fenêtre, exécuter les commandes suivantes pour avoir accès au logs de l'installation du cluster :
    ```    
    sudo su 
    tail -f /var/log/syslog
    ```
    NB: L'installation est terminée lorsque vous voyez : **Everything is setup. Cluster and Apps are ready to use!**
10. Dans cette fenêtre, une fois l'installation terminée, exécuter les commandes suivantes pour avoir accès au remote kubectl :
    ```    
    sudo su 
    cd /root/kubespray
    source /root/.bashrc
    kubectl get nodes
    kubectl get pods
    ```

### Arrêt

1. Quitter la fenêtre SSH de _workstation_
2. Dans le _cloud shell_, saisir : `terraform destroy`

## Liens utiles

- [GCE](https://console.cloud.google.com/)
- [Kubespray](https://github.com/kubernetes-sigs/kubespray)
- [Terraform](https://www.terraform.io/)


