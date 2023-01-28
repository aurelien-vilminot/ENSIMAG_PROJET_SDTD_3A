#!/usr/bin/env python3
import argparse
import json
import time

from kafka import KafkaConsumer
from prometheus_client import start_http_server, Gauge


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

    def consume_stats(self) -> None:
        print(f"[Stats consumer] Listening on topic {self.topic_name}!")

        # Create a metric to track the time spent processing a million tweets.
        prom_metric = Gauge('time_per_million_tweets', 'Time per million tweets')
        prom_metric.set(0)
        millions = 0

        for message in self.consumer:
            # Start the timer
            time_beg = time.time()

            stats_json = message.value
            self.nb_tweet_consumed += int(stats_json['nb_tweet_consumed'])
            self.nb_tweet_with_bad_words += int(stats_json['nb_tweet_with_bad_words'])
            self.nb_bad_words += int(stats_json['nb_bad_words'])
            self.log_stats()

            # Update the metric
            current_millions = self.nb_tweet_consumed // 1000000
            if current_millions != millions:
                millions = current_millions
                prom_metric.set(0)
            else:
                prom_metric.inc(time.time() - time_beg)

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
    start_http_server(8888)

    # Init the producer
    sc = StatsConsumer(args.topic_name[0].strip(), server_addresses)
    sc.consume_stats()
