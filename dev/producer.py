#!/usr/bin/env python3

import argparse
import csv
import json
from datetime import datetime
from pathlib import Path

import tweepy

from kafka import KafkaProducer


class TwitterStreamer:
    def __init__(self, topic_name: str, bootstrap_servers: list):
        with open('config.json') as f:
            config = json.load(f)

        access_token = config["access_token"]
        access_token_secret = config["access_token_secret"]
        consumer_key = config["api_key"]
        consumer_secret = config["api_key_secret"]
        self.bearer_token = config["bearer_token"]
        self.topic_name = topic_name

        self.producer = KafkaProducer(bootstrap_servers=bootstrap_servers,
                                      value_serializer=lambda x: json.dumps(x).encode('utf8')
                                      )  # Same port as your Kafka server

        tweepy.OAuth1UserHandler(consumer_key, consumer_secret, access_token, access_token_secret)
        self.streaming_client = None

    def stream_tweets(self, stream_local_tweet=False):
        if stream_local_tweet:
            local_stream = LocalProducer(self.producer, self.topic_name)
            print(f'[Producer] Streaming fake tweets on topic {self.topic_name}!')
            local_stream.stream_tweets()
        else:
            self.streaming_client = TwitterListener(self.bearer_token)
            self.streaming_client.setup(self.producer, self.topic_name)
            self.remove_all_rules()
            # https://developer.twitter.com/en/docs/twitter-api/tweets/filtered-stream/integrate/build-a-rule#build
            # streaming_client.add_rules(tweepy.StreamRule('"breaking news" -is:retweet')) --> rt filter
            # streaming_client.sample() --> get all tweets
            # self.streaming_client.add_rules(tweepy.StreamRule('lang:en')) --> règle conjonctive, à associer avec autre chose...
            self.streaming_client.add_rules(tweepy.StreamRule('musk lang:en'))
            print(f'[Producer] Streaming real tweets on topic {self.topic_name}!')
            # self.streaming_client.sample()
            self.streaming_client.filter()

    def remove_all_rules(self):
        rules = self.streaming_client.get_rules()
        if not rules.data:
            return
        rules_id = [stream_rule.id for stream_rule in rules.data]
        if len(rules_id) != 0:
            print(f"Deleting rules {rules_id}")
            self.streaming_client.delete_rules(rules_id)


class TwitterListener(tweepy.StreamingClient):
    def setup(self, producer: KafkaProducer, topic_name: str):
        self.producer = producer
        self.topic_name = topic_name

    def on_tweet(self, tweet):
        # Impossible de récupérer tweet.lang, toujours None (mais filtrer avec lang:fr marche)
        print(f'Sent tweet: {tweet.text}')
        tweet_json = {'text': tweet.text, 'datetime': datetime.utcnow().timestamp(), 'lang': tweet.lang}
        self.producer.send(self.topic_name, value=tweet_json)

    def on_errors(self, errors):
        self.producer.flush()
        return super().on_errors(errors)

    def on_disconnect(self):
        self.producer.flush()
        return super().on_disconnect()


class LocalProducer:
    def __init__(self, producer: KafkaProducer, topic_name: str):
        self.producer = producer
        self.topic_name = topic_name
        self.tweet_csv_file_path = Path(__file__).parent.joinpath("data/tweets.csv")

        with open(self.tweet_csv_file_path, "r", encoding='Latin1') as csv_file:
            csv_reader = csv.reader(csv_file)
            self.tweet_list = [{'text': tweet_content[0]} for tweet_content in csv_reader if tweet_content[0]]

    def stream_tweets(self) -> None:
        for num, tweet_json in enumerate(self.tweet_list):
            self.producer.send(self.topic_name, value=tweet_json)
            if (num + 1) % 1000 == 0:
                print(f"{num + 1} tweets sent")
        # Flush on exit
        self.producer.flush()


if __name__ == "__main__":
    # Parse args
    parser = argparse.ArgumentParser(description="Kafka producer")
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

    # Init the producer
    ts = TwitterStreamer(args.topic_name[0].strip(), server_addresses)
    local_tweet = True
    ts.stream_tweets(local_tweet)
