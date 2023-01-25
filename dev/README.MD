# Avant-propos

Ce répertoire contient les fichiers utilisés par les images déployées sur Docker Hub. Il peut donc être consulté et/ou
modifié sans impact sur le fonctionnement de l'application tant que les modifications ne sont pas poussées sur Docker
Hub.

# Docker

Kafka se lance alors en fond de tâche et les tweets sont transmis du producer au consumer. Pour observer les échanges,
il faut ouvrir le terminal du docker concerné (producer ou consumer) via l'interface de Docker Desktop, ou avec la
commande `docker ps` puis `docker logs [container-name]`

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

# Docker Hub

Pour déployer l'image sur Docker Hub, faire, pour chaque Dockerfile, les commandes suivantes:

```
docker-compose build (if the images are not yet built)
docker login -u LOGIN (ex: docker login -u thecsmine)
docker tag IMG_NAME:VERSION LOGIN/REPO:IMG_NAME (ex: docker tag docker-zookeeper:latest thecsmine/sdtd:zookeeper)
docker push LOGIN/REPO:IMG_NAME (ex: docker push thecsmine/sdtd:zookeeper)
```

# Performances (_notes pour l'équipe DEV_)

`re.sub("@\w*", "", content)` vs `content.replace("@", "")` : sur 55 900 appels sur un même jeu de tweets, on obtient
3100ns vs 1000ns => l'expression régulière est donc trop coûteuse par rapport à la fonction native Python.

`clean_tweet(tweet_content: str)` : avec des expressions régulières, 0.95s. Sans, 0.56s.

`word_tokenize(tweet_content, language="english")` vs `tweet_content.split(" ")` : 24s vs 4s => problème, pas le même
nombre de bad words à la fin du programme. Par exemple, pour le tweet "_nazi,_" nltk extrait uniquement le mot "_nazi_"
alors que `split(" ")` laisse la virgule ce qui empêche la détection du mot.

Temps d'exécution du producer en local : `Timer producer : 53.463799715042114s`

11.14% of bad words for a total of 983000 tweets.

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

- https://learnk8s.io/kafka-ha-kubernetes
- https://levelup.gitconnected.com/how-to-deploy-apache-kafka-with-kubernetes-9bd5caf7694f
