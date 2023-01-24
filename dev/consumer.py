#!/usr/bin/env python3
import argparse
import json
import os
import re
from pathlib import Path

import nltk
from nltk.tokenize import word_tokenize

from kafka import KafkaConsumer
from kafka import KafkaProducer
from process_word_list import DataProcessor

nltk.download('punkt')


class TwitterConsumer:
    def __init__(self, topic_name: str, group_id: str, bootstrap_servers: list):
        self.consumer = KafkaConsumer(
            topic_name,
            group_id=group_id,
            bootstrap_servers=bootstrap_servers,
            # latest, earliest or none (https://www.conduktor.io/kafka/consumer-auto-offsets-reset-behavior)
            auto_offset_reset='earliest',
            max_poll_interval_ms=5000,
            max_poll_records=1000,
            enable_auto_commit=True,  # offsets are committed automatically
            auto_commit_interval_ms=10000,  # frequency of commits
            value_deserializer=lambda x: json.loads(x.decode('utf-8')))

        self.topic_name = topic_name
        self.group_id = group_id
        self.stats_producer = StatsProducer("stats", bootstrap_servers)
        self._load_bad_words_files()
        self._init_counter()

    def _init_counter(self):
        self.stats_nb_tweet_consumed = 0
        self.stats_nb_tweet_with_bad_words = 0
        self.stats_nb_bad_words = 0
        self.total_nb_tweet_consumed = 0
        self.total_nb_tweet_with_bad_words = 0
        self.total_nb_bad_words = 0

    def _reset_counter(self):
        self.stats_nb_tweet_consumed = 0
        self.stats_nb_tweet_with_bad_words = 0
        self.stats_nb_bad_words = 0

    def consume_tweet(self) -> None:
        print(f"[Consumer] Listening on topic {self.topic_name} in group {self.group_id}!")
        for message in self.consumer:
            tweet_json = message.value
            tweet_content = tweet_json['text']

            tweet_content = self._clean_tweet(tweet_content)
            self.natural_language_process(tweet_content)
        print("Flushing stats_producer...")
        self.stats_producer.flush()
        print("Flushing stats_producer finished")

    def _clean_tweet(self, tweet_content: str) -> str:
        # Remove user mentions
        clean_tweet_content = self._remove_mention(tweet_content)

        # Remove '#' character
        clean_tweet_content = self._remove_hashtag(clean_tweet_content)

        # Put tweet in lowercase
        clean_tweet_content = clean_tweet_content.lower()

        # Delete 'rt' keyword
        clean_tweet_content = self._delete_keywords(clean_tweet_content)

        # Remove urls
        clean_tweet_content = self._remove_url(clean_tweet_content)

        return clean_tweet_content

    @staticmethod
    def _remove_url(content: str) -> str:
        return " ".join(re.sub("http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+", "",
                               content).split())

    @staticmethod
    def _remove_mention(content: str) -> str:
        return content.replace("@", "")

    @staticmethod
    def _remove_hashtag(content: str) -> str:
        return content.replace("#", "")

    @staticmethod
    def _delete_keywords(content: str) -> str:
        keywords = ["rt"]
        for keyword in keywords:
            content = content.replace(keyword, "")
        return content

    def natural_language_process(self, tweet_content: str) -> None:
        # Work only with english language
        tweet_words = word_tokenize(tweet_content, language="english")
        detected_bad_words = []
        for words_len in self.words_en:
            for tweet_word_index in range(0, len(tweet_words), words_len):
                # Construction of subtweet
                sub_tweet_words = ""
                for sub_tweet_word_index in range(tweet_word_index, tweet_word_index + words_len):
                    if sub_tweet_word_index < len(tweet_words):
                        # Add space removing by word_tokenize()
                        sub_tweet_words += " " + tweet_words[sub_tweet_word_index]

                # strip() is used to remove useless trailing spaces
                sub_tweet_words = sub_tweet_words.strip()

                # Check if the part of tweet contains bad words
                if sub_tweet_words in self.words_en[words_len]:
                    detected_bad_words.append(sub_tweet_words)

        self.stats_nb_tweet_consumed += 1
        self.total_nb_tweet_consumed += 1
        if len(detected_bad_words) > 0:
            self.stats_nb_bad_words += len(detected_bad_words)
            self.total_nb_bad_words += len(detected_bad_words)
            self.stats_nb_tweet_with_bad_words += 1
            self.total_nb_tweet_with_bad_words += 1

        if self.total_nb_tweet_consumed % 1000 == 0:
            # Percentage send every 1000 tweets analysed
            stats = {
                'nb_tweet_with_bad_words': self.stats_nb_tweet_with_bad_words,
                'nb_tweet_consumed': self.stats_nb_tweet_consumed,
                'nb_bad_words': self.stats_nb_bad_words
            }
            self.stats_producer.send_stats(stats)
            self._reset_counter()
            self.log_stats()
        if self.total_nb_tweet_consumed % 10000 == 0:
            print(f'\t The {self.total_nb_tweet_consumed}th tweet is: {tweet_content}')

    def _load_bad_words_files(self) -> None:
        filenames_en = [x for x in os.listdir(Path(__file__).parent.joinpath("data/")) if
                        re.match("bad_words_en_[0-9]*.csv", str(x))]
        self.words_en = dict()
        for words_len, filename_en in enumerate(filenames_en):
            self.words_en[words_len + 1] = DataProcessor.get_set_from_csv(
                Path(__file__).parent.joinpath(f"data/{filename_en}"))

    def log_stats(self) -> None:
        print(
            f'\t ==> {round(((self.total_nb_tweet_with_bad_words / self.total_nb_tweet_consumed) * 100), 2)}% of bad words '
            f'for a total of {self.total_nb_tweet_consumed} tweets ({self.total_nb_bad_words} bad words in total).')


class StatsProducer:
    def __init__(self, topic_name: str, bootstrap_servers: list):
        self.topic_name = topic_name
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda x: json.dumps(x).encode('utf8')
        )

    def send_stats(self, value: json) -> None:
        self.producer.send(self.topic_name, value=value)

    def flush(self) -> None:
        self.producer.flush()


if __name__ == "__main__":
    # Parse args
    parser = argparse.ArgumentParser(description="Kafka consumer")
    parser.add_argument(
        "bootstrap_servers",
        type=str,
        nargs=1,
        help="(str) The server addresses and corresponding ports (xxx.xxx.xxx.xxx:xxxx). If multiple, split them by a "
             "coma."
    )
    parser.add_argument("topic_name", type=str, nargs=1, help="(str) The topic name")
    parser.add_argument("group_id", type=str, nargs=1, help="(str) The group id")
    args = parser.parse_args()
    server_addresses = [address.strip() for address in args.bootstrap_servers[0].split(',')]

    # Init the producer
    tc = TwitterConsumer(args.topic_name[0].strip(), args.group_id[0].strip(), server_addresses)
    tc.consume_tweet()
