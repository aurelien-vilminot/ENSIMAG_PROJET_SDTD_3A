# Projet de Systèmes Distribués pour le Traitement de Données

## Équipe

* Alexis BRUNO
* Laure CERUTTI
* Damien CLAUZON
* Félix GANDER
* Arthur SARRY
* Aurélien VILMINOT

## Organisation

Le dossier `deploiement/` contient les fichiers nécessaires pour que le déploiement de l'application se fasse sur Google
Cloud.

Le dossier `dev/` contient les ressources utilisées pour la partie développement de l'application. Ces fichiers ne sont
pas directement utilisés par Google Cloud lors du déploiement. En effet, l'ensemble est contenu dans diverses images
Docker présentent sur la plateforme Docker Hub.

## Déploiement de l'application sur Google Cloud

### Démarrage

1. Se rendre sur la console [Google Cloud](https://console.cloud.google.com)
2. Démarrer un projet si ce n'est pas déjà fait
3. Prérequis, avoir activé le service Compute Engine (voir ci-dessous)
4. Ouvrir le _cloud shell_ via l'icône en haut à droite
5. Dans la console _cloud shell_ venant de s'ouvrir :
    ```
    git clone https://github.com/aurelien-vilminot/SDTD_Github
    cd ./deploiement/terraform
    bash start.sh <id_projet_gcloud>
    ```
6. Depuis le menu, se rendre dans *Compute Engine* > *Instances de VM*
7. Sur l'instance **workstation**, cliquer sur _SSH_
8. Dans la nouvelle fenêtre, exécuter les commandes suivantes pour avoir accès aux logs de l'installation du cluster :
    ```    
    sudo su 
    tail -f /var/log/syslog
    ```
   NB : L'installation est terminée lorsque vous voyez : **_Everything is setup. Cluster and Apps are ready to use!_**
9. Dans cette fenêtre, une fois l'installation terminée, exécuter les commandes suivantes pour avoir accès au _remote
   kubectl_ :
   ```
   source /root/.bashrc
   kubectl get nodes
   kubectl get pods
   ```
10. Pour accéder à Prometheus et Grafana, se rendre dans *Compute Engine* > *Instances de VM* et récupérer une adresse externe du cluster puis se connecter via un navigateur internet aux adresses suivantes : 
       ```
       Prometheus : http://X.X.X.X:32000
       Grafana : http://X.X.X.X:32001
       ```

### Arrêt

1. Quitter la fenêtre SSH de _workstation_
2. Dans le _cloud shell_, toujours dans le répertoire `./deploiement/terraform` saisir : `terraform destroy`

### Activation du service _Compute Engine API_

1. Depuis le menu, se rendre dans _API et services_
2. Ajouter le service **Compute Engine API** et **Logging API** en cliquant sur _Activer les API et les services_

## Liens utiles

- [GCE](https://console.cloud.google.com/)
- [Kubespray](https://github.com/kubernetes-sigs/kubespray)
- [Terraform](https://www.terraform.io/)


