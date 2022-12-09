FROM debian:latest

WORKDIR /code

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install -y default-jdk net-tools telnet netcat

COPY ../kafka ./kafka
COPY ../zookeeper.properties ./
COPY ../config.json ./

CMD bash -c "./kafka/bin/zookeeper-server-start.sh ./zookeeper.properties"