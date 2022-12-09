FROM debian:latest

WORKDIR /code

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install -y python3 python3-pip

COPY ../requirements.txt ./
COPY ../consumer.py ./
COPY ../config.json ./
COPY ../data ./data/

# Install Python dependencies
RUN pip install -r requirements.txt
