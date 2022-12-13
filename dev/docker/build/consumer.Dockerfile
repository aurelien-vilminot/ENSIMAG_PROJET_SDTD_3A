FROM debian:latest

WORKDIR /code

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install -y python3 python3-pip

COPY ../requirements.txt ./
COPY ../consumer.py ./
COPY ../process_word_list.py ./
COPY ../data/ ./data/
COPY ../wait_for_server.sh ./

# Install Python dependencies
RUN pip install -r requirements.txt

# Run consumer after Kafka server started and wait 5s for producer start
CMD bash -c "./wait_for_server.sh kafka:9092 -- sleep 5; python3 ./consumer.py kafka:9092 tweepykafka"