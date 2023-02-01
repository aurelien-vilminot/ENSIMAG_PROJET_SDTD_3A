# Avant-propos

Ce répertoire contient les fichiers utilisés par les images déployées sur Docker Hub. Il peut donc être consulté et/ou
modifié sans impact sur le fonctionnement de l'application tant que les modifications ne sont pas poussées sur Docker
Hub.

# Docker

Les images sont faites pour être lancés avec Kubernetes via `kubectl apply -f deploiement/kubectl/kafka_cluster.yml`, et
non avec Docker Compose qui n'est utilisé ici que pour construire les images rapidement. Kafka se lance alors en fond de
tâche et les tweets sont transmis du producer au consumer. Pour observer les échanges, il faut ouvrir le terminal du
docker concerné (producer ou consumer) via l'interface de Docker Desktop, ou avec la
commande `docker ps` puis `docker logs [container-name]`.

Deux options existent pour démarrer le conteneur :

# Docker Hub

Pour déployer l'image sur Docker Hub, faire, pour chaque Dockerfile, les commandes suivantes:

```
docker-compose build (if the images are not yet built)
docker login -u LOGIN (ex: docker login -u thecsmine)
docker tag IMG_NAME:VERSION LOGIN/REPO:IMG_NAME (ex: docker tag docker-zookeeper:latest thecsmine/sdtd:zookeeper)
docker push LOGIN/REPO:IMG_NAME (ex: docker push thecsmine/sdtd:zookeeper)
```

# Kafka

Pour exécuter Kafka en local :

1. Lancer Zookeeper
2. Lancer le serveur
3. Créer le topic (sauf si déjà fait précédemment)
4. Exécuter `producer.py localhost:9092 tweepykafka` puis `consumer.py localhost:9092 tweepykafka`

## Windows

- Zookeeper

```bash
.\kafka\bin\windows\zookeeper-server-start.bat .\zookeeper.properties
```

- Serveur

```bash
.\kafka\bin\windows\kafka-server-start.bat .\server.properties
```

- Création topic _tweepykafka_

```bash
.\kafka\bin\windows\kafka-topics.bat --bootstrap-server localhost:9092 --create --replication-factor 1 --partitions 2 --topic tweepykafka
```

- Lister tous les topics

```bash
.\kafka\bin\windows\kafka-topics.bat --bootstrap-server localhost:9092 --list
```

- Supprimer tous les topics

```bash
.\kafka\bin\windows\kafka-topics.bat --bootstrap-server localhost:9092 --delete --topic '*'
```

## Linux

- Zookeeper

```bash
./kafka/bin/zookeeper-server-start.sh ./zookeeper.properties
```

- Serveur

```bash
./kafka/bin/kafka-server-start.sh ./server.properties
```

- Création topic _tweepykafka_

```bash
./kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --replication-factor 1 --partitions 2 --topic tweepykafka
```

- Lister tous les topics

```bash
./kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

# Ressources

- [Learnk8s - Deploy Kafka with Kubernetes](https://learnk8s.io/kafka-ha-kubernetes)
- [Levelup - Kafka on Kubernetes](https://levelup.gitconnected.com/how-to-deploy-apache-kafka-with-kubernetes-9bd5caf7694f)
