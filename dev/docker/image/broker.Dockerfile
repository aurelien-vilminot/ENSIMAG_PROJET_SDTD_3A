FROM debian:latest

WORKDIR /code

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install -y default-jdk netcat

COPY ../kafka ./kafka
COPY ../server.properties ./
COPY ../config.json ./
COPY ../wait_for_server.sh ./

CMD bash -c "./wait_for_server.sh localhost:9092 && ./kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --replication-factor 1 --partitions 3 --topic tweepykafka && ./kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --replication-factor 1 --partitions 1 --topic stats & ./wait_for_server.sh zookeeper:2181 && ./kafka/bin/kafka-server-start.sh ./server.properties"