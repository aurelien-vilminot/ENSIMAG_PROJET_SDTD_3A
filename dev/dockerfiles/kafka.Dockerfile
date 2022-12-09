FROM debian:latest

WORKDIR /code

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install -y default-jdk net-tools telnet netcat

COPY ../kafka ./kafka
COPY ../server.properties ./
COPY ../config.json ./


CMD bash -c "./kafka/bin/kafka-server-start.sh ./server.properties"
#CMD bash -c "./kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --replication-factor 1 --partitions 2 --topic tweepykafka"