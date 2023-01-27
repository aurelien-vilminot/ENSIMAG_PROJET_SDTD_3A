#!/usr/bin/env python3
import argparse
import json

from kafka import KafkaConsumer
from prometheus_client import start_http_server, Summary

# Create a metric to track time spent and requests made.
REQUEST_TIME = Summary('request_processing_seconds', 'Time spent processing request')

class StatsConsumer:
    def __init__(self, topic_name: str, bootstrap_servers: list):
        self.consumer = KafkaConsumer(
            topic_name,
            bootstrap_servers=bootstrap_servers,
            # latest, earliest or none (https://www.conduktor.io/kafka/consumer-auto-offsets-reset-behavior)
            auto_offset_reset='earliest',
            max_poll_interval_ms=5000,
            max_poll_records=1000,
            enable_auto_commit=True,  # offsets are committed automatically
            auto_commit_interval_ms=10000,  # frequency of commits
            value_deserializer=lambda x: json.loads(x.decode('utf-8')))

        self.topic_name = topic_name
        self.nb_tweet_consumed = 0
        self.nb_tweet_with_bad_words = 0
        self.nb_bad_words = 0

<<<<<<< HEAD
    @REQUEST_TIME.time()
    def consume_tweet(self) -> None:
=======
    def consume_stats(self) -> None:
>>>>>>> af2979eff2ea14aa829cef2dcc9a1e155612a6e5
        print(f"[Stats consumer] Listening on topic {self.topic_name}!")
        for message in self.consumer:
            stats_json = message.value
            self.nb_tweet_consumed += int(stats_json['nb_tweet_consumed'])
            self.nb_tweet_with_bad_words += int(stats_json['nb_tweet_with_bad_words'])
            self.nb_bad_words += int(stats_json['nb_bad_words'])
            self.log_stats()

    def log_stats(self) -> None:
        print(
            f'\t ==> {round(((self.nb_tweet_with_bad_words / self.nb_tweet_consumed) * 100), 2)}% of bad words '
            f'for a total of {self.nb_tweet_consumed} tweets ({self.nb_bad_words} bad words in total).')


if __name__ == "__main__":
    # Parse args
    parser = argparse.ArgumentParser(description="Stats consumer")
    parser.add_argument(
        "bootstrap_servers",
        type=str,
        nargs=1,
        help="(str) The server addresses and corresponding ports (xxx.xxx.xxx.xxx:xxxx). If multiple, split them by a "
             "coma."
    )
    parser.add_argument("topic_name", type=str, nargs=1, help="(str) The topic name")
    args = parser.parse_args()
    server_addresses = [address.strip() for address in args.bootstrap_servers[0].split(',')]

    # Start up the server to expose the metrics.
    start_http_server(8088)

    # Init the producer
    sc = StatsConsumer(args.topic_name[0].strip(), server_addresses)
    sc.consume_stats()
