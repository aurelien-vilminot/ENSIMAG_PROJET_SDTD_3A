# Docker

Kafka se lance alors en fond de tâche et les tweets sont transmis du producer au consumer. Pour observer les échanges,
il faut ouvrir le terminal du docker concerné (producer ou consumer) via l'interface de Docker Desktop, ou avec la commande `docker ps` puis `docker logs [container-name]`

Deux options existent pour démarrer le conteneur :

## Pull & run

1. Se placer dans le répertoire `dev/docker/`
2. Saisir les commandes suivantes pour supprimer les conteneurs en cours, pull les images, et lancer le conteneur :

```
docker-compose stop
docker-compose rm -f
docker-compose pull
docker-compose up -d
```

## Build & run

1. Se placer dans le répertoire `dev/docker/build`
2. Saisir les commandes suivantes pour supprimer les conteneurs en cours, build les images, et lancer le conteneur :

```
docker-compose stop
docker-compose rm -f
docker-compose build
docker-compose up -d
```

# How to push to Docker Hub

Pour chaque Dockerfile, faire la suite de commandes suivante:

```
docker-compose build (if the images are not yet built)
docker login -u LOGIN (ex: docker login -u thecsmine)
docker tag IMG_NAME:VERSION LOGIN/REPO:IMG_NAME (ex: docker tag docker-zookeeper:latest thecsmine/sdtd:zookeeper)
docker push LOGIN/REPO:IMG_NAME (ex: docker push thecsmine/sdtd:zookeeper)
```

# Performances [dev]

`re.sub("@\w*", "", content)` vs `content.replace("@", "")` : sur 55 900 appels sur un même jeu de tweets, on obtient
3100ns vs 1000ns => l'expression régulière est donc trop coûteuse par rapport à la fonction native Python.

`clean_tweet(tweet_content: str)` : avec des expressions régulières, 0.95s. Sans, 0.56s.

`word_tokenize(tweet_content, language="english")` vs `tweet_content.split(" ")` : 24s vs 4s => problème, pas le même
nombre de bad words à la fin du programme. Par exemple, pour le tweet "_nazi,_" nltk extrait uniquement le mot "_nazi_"
alors que `split(" ")` laisse la virgule ce qui empêche la détection du mot.

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

```
./kafka/bin/zookeeper-server-start.sh ./zookeeper.properties
```

- Serveur

```
./kafka/bin/kafka-server-start.sh ./server.properties
```

- Création topic _tweepykafka_

```
./kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --replication-factor 1 --partitions 2 --topic tweepykafka
```

- Lister tous les topics

```
./kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

# Cluster

- https://learnk8s.io/kafka-ha-kubernetes

1. Grab k3d executable [here](https://github.com/k3d-io/k3d/releases)

2. Create a three-node cluster that spans three availability
   zones: `./k3d.exe cluster create kube-cluster --agents 3 --k3s-node-label topology.kubernetes.io/zone=zone-a@agent:0 --k3s-node-label topology.kubernetes.io/zone=zone-b@agent:1 --k3s-node-label topology.kubernetes.io/zone=zone-c@agent:2`

   Verify it is ready with: `kubectl get nodes`

3. Define the resources required for a Kafka cluster then apply: `kubectl apply -f yaml/kafka.yaml`

   Wait for the resources created to be ready with: `kubectl get -f yaml/kafka.yaml`

   There is a StatefulSet with three ready Kafka broker pods and a service. It maintains the availability of the three
   pods. Verify that with: `kubectl get pods` (you can try to delete with `kubectl delete pod kafka-0` and then check
   again)

   There are also three independent PersistentVolumeClaims for storing Kafka data, one for each broker. Verify that
   with: `kubectl get pvc,pv`

4. Get server's endpoints with: `kubectl describe service kafka-svc`

   Copy the three IP addresses, and use them in the following commands to test out from a pod:
   `kubectl run kafka-client --rm -ti --image bitnami/kafka:latest -- bash`

   `kafka-console-producer.sh --topic test --request-required-acks all --bootstrap-server 10.42.0.11:9092,10.42.0.9:9092,10.42.1.4:9092`
   --> write things here

   `kafka-console-consumer.sh \ --topic test \ --from-beginning \ --bootstrap-server 10.42.0.11:9092,10.42.0.9:9092,10.42.1.4:9092`
   --> will consume the things from before

5. The tutorial explains how to test with a broker server down or pending, then explains how to implement pod topology
   to spread pods across different domains.

- https://levelup.gitconnected.com/how-to-deploy-apache-kafka-with-kubernetes-9bd5caf7694f

1. Defining Kafka namespace : `kubectl apply -f ./yaml/namespace.yaml`
2. todo
