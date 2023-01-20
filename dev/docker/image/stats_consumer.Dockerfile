FROM debian:latest

WORKDIR /code

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install -y python3 python3-pip

COPY ../requirements.txt ./
COPY ../stats_consumer.py ./
COPY ../wait_for_server.sh ./

# Install Python dependencies
RUN pip install -r requirements.txt

# Run stats consumer after Kafka server started
CMD bash -c "./wait_for_server.sh broker:9092; python3 ./stats_consumer.py broker:9092 stats"