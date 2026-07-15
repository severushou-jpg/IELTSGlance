#!/usr/bin/env python3
"""Normalize the project-authored seed TSV into the app's bundled JSON resource."""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "data" / "gre_words_seed.tsv"
DEFAULT_OUTPUT = ROOT / "Shared" / "Resources" / "gre_words.json"


def stable_id(word: str) -> str:
    normalized = re.sub(r"[^a-z0-9]+", "-", word.strip().lower()).strip("-")
    return f"gre-{normalized}"


def import_words(source: Path) -> list[dict[str, object]]:
    with source.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="|")
        expected = {
            "word",
            "partOfSpeech",
            "chineseMeaning",
            "synonyms",
            "exampleSentence",
            "source",
        }
        if set(reader.fieldnames or []) != expected:
            raise ValueError(f"Unexpected columns: {reader.fieldnames}")

        words: list[dict[str, object]] = []
        for line_number, row in enumerate(reader, start=2):
            word = row["word"].strip().lower()
            if not word:
                raise ValueError(f"Line {line_number}: empty word")
            synonyms = [item.strip().lower() for item in row["synonyms"].split(",") if item.strip()]
            words.append(
                {
                    "id": stable_id(word),
                    "word": word,
                    "partOfSpeech": row["partOfSpeech"].strip(),
                    "chineseMeaning": row["chineseMeaning"].strip(),
                    "synonyms": synonyms,
                    "exampleSentence": row["exampleSentence"].strip(),
                    "source": row["source"].strip() or None,
                }
            )
    return sorted(words, key=lambda item: str(item["word"]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    words = import_words(args.input)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(words, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Imported {len(words)} words -> {args.output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
