FROM debian:latest

WORKDIR /code

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install -y default-jdk

COPY ../kafka ./kafka
COPY ../server.properties ./
COPY ../zookeeper.properties ./
COPY ../config.json ./

#TODO: launch Zookeeper and Kafka
#CMD bash -c "./kafka/bin/zookeeper-server-start.sh ./zookeeper.properties && ./kafka/bin/kafka-server-start.sh ./server.properties"