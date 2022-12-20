FROM debian:latest

WORKDIR /code

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install -y python3 python3-pip

COPY ../requirements.txt ./
COPY ../producer.py ./
COPY ../config.json ./
COPY ../data ./data/
COPY ../wait_for_server.sh ./

# Install Python dependencies
RUN pip install -r requirements.txt

# Run consumer after Kafka server started
CMD bash -c "./wait_for_server.sh localhost:9092; python3 ./producer.py localhost:9092 tweepykafka"