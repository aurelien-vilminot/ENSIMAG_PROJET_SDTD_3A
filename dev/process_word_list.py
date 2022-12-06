import csv
import os.path
from pathlib import Path

from nltk import word_tokenize

BAD_WORDS_EN_FILE_PATH = Path(__file__).parent / "data/bad_words_en.csv"
BAD_WORDS_FR_FILE_PATH = Path(__file__).parent / "data/bad_words_fr.csv"
BRUT_DATA_EN_PATH = Path(__file__).parent / "data/brut/en"
BRUT_DATA_FR_PATH = Path(__file__).parent / "data/brut/fr"


class DataProcessor:
    def __init__(self):
        if os.path.exists(BAD_WORDS_EN_FILE_PATH):
            self.bad_words_en = self.get_set_from_csv(BAD_WORDS_EN_FILE_PATH)
        else:
            self.bad_words_en = set()

        if os.path.exists(BAD_WORDS_FR_FILE_PATH):
            self.bad_words_fr = self.get_set_from_csv(BAD_WORDS_FR_FILE_PATH)
        else:
            self.bad_words_fr = set()

    def add_brut_data(self) -> None:
        brut_en_data = set()
        for file in os.listdir(BRUT_DATA_EN_PATH):
            if Path(str(file)).suffix == ".csv":
                brut_en_data.update(self.get_set_from_csv(f"{BRUT_DATA_EN_PATH.joinpath(str(file))}"))

        brut_fr_data = set()
        for file in os.listdir(BRUT_DATA_FR_PATH):
            if Path(str(file)).suffix == ".csv":
                brut_fr_data.update(self.get_set_from_csv(f"{BRUT_DATA_FR_PATH.joinpath(str(file))}"))

        old_en_len = len(self.bad_words_en)
        old_fr_len = len(self.bad_words_fr)
        self.bad_words_en.update(brut_en_data)
        self.bad_words_fr.update(brut_fr_data)

        print(f"{len(self.bad_words_en) - old_en_len} english bad words added.")
        print(f"{len(self.bad_words_fr) - old_fr_len} french bad words added.")

        self._add_set_to_csv(BAD_WORDS_EN_FILE_PATH, self.bad_words_en)
        self._add_set_to_csv(BAD_WORDS_FR_FILE_PATH, self.bad_words_fr)

    @staticmethod
    def get_set_from_csv(file_path) -> set:
        with open(file_path, "r") as csv_file:
            csv_reader = csv.reader(csv_file)
            return set(word[0] for word in csv_reader)

    @staticmethod
    def _add_set_to_csv(file_path, data: set) -> None:
        with open(file_path, "w", newline='') as csv_file:
            csv_writter = csv.writer(csv_file)
            for word in data:
                csv_writter.writerow([word.strip('\n')])

    def dispatch_words_by_length(self):
        bad_words = self.get_set_from_csv(BAD_WORDS_EN_FILE_PATH)
        bad_words_dict = dict()
        for word in bad_words:
            tweet_words = word_tokenize(word, language="english")
            try:
                words_set = bad_words_dict[len(tweet_words)]
                words_set.add(word)
            except KeyError:
                bad_words_dict[len(tweet_words)] = set()
                bad_words_dict[len(tweet_words)].add(word)

        for len_words_set in bad_words_dict:
            self._add_set_to_csv(
                Path(__file__).parent.joinpath(f"data/bad_words_en_{len_words_set}.csv"),
                bad_words_dict[len_words_set]
            )

        bad_words = self.get_set_from_csv(BAD_WORDS_FR_FILE_PATH)
        bad_words_dict = dict()
        for word in bad_words:
            tweet_words = word_tokenize(word, language="french")
            try:
                words_set = bad_words_dict[len(tweet_words)]
                words_set.add(word)
            except KeyError:
                bad_words_dict[len(tweet_words)] = set()
                bad_words_dict[len(tweet_words)].add(word)

        for len_words_set in bad_words_dict:
            self._add_set_to_csv(
                Path(__file__).parent.joinpath(f"data/bad_words_fr_{len_words_set}.csv"),
                bad_words_dict[len_words_set]
            )


if __name__ == "__main__":
    dataProcess = DataProcessor()
    dataProcess.add_brut_data()
    dataProcess.dispatch_words_by_length()
