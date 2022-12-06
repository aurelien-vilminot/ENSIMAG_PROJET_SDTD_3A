#!/usr/bin/env python3
import csv
import os
import re
import time
from pathlib import Path

from nltk import word_tokenize

from dev.process_word_list import DataProcessor


class PerformancesTester:
    def __init__(self):
        self.bad_tweet = []
        self._load_bad_words_files()
        self.times = []
        self.tweet_csv_file_path = Path(__file__).parent.joinpath("data/tweets_dataset.csv")
        with open(self.tweet_csv_file_path, "r", encoding='Latin1') as csv_file:
            csv_reader = csv.reader(csv_file)
            # Skip header
            next(csv_reader)
            self.tweet_list = [{'text': tweet_content[11]} for tweet_content in csv_reader if tweet_content[11]]

    def stream_tweets(self) -> None:
        for tweet_json in self.tweet_list:
            tweet_text = tweet_json["text"]
            tweet_content = self._clean_tweet(tweet_text)
            self.natural_language_process(tweet_content)

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
        # Work only with english language (TODO for french)
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

        if len(detected_bad_words) > 0:
            # print(f"\t ==> This tweet has {len(detected_bad_words)} bad words.\n{detected_bad_words}")
            self.bad_tweet.append(detected_bad_words)

    def _load_bad_words_files(self) -> None:
        filenames_en = [x for x in os.listdir(Path(__file__).parent.joinpath("data/")) if
                        re.match("bad_words_en_[0-9]*.csv", str(x))]
        self.words_en = dict()
        for words_len, filename_en in enumerate(filenames_en):
            self.words_en[words_len + 1] = DataProcessor.get_set_from_csv(
                Path(__file__).parent.joinpath(f"data/{filename_en}"))

        filenames_fr = [x for x in os.listdir(Path(__file__).parent.joinpath("data/")) if
                        re.match("bad_words_fr_[0-9]*.csv", str(x))]
        self.words_fr = dict()
        for words_len, filename_fr in enumerate(filenames_fr):
            self.words_fr[words_len + 1] = DataProcessor.get_set_from_csv(
                Path(__file__).parent.joinpath(f"data/{filename_fr}"))


if __name__ == "__main__":
    tc = PerformancesTester()

    start_time = time.time()
    tc.stream_tweets()
    print(f'Execution time for stream_tweets() : {(time.time() - start_time)}s.')

    print(tc.bad_tweet)

    # total = 0
    # for time_recorded in tc.times:
    #     total += time_recorded
    # print(f'Execution time for function : {total / len(tc.times)}ns.')
