#!/usr/bin/env python3
"""Validate the bundled 15×100 IELTS pack resource."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PATH = ROOT / "Shared" / "Resources" / "ielts_word_packs.json"
VALID_PARTS_OF_SPEECH = {"adj.", "adv.", "n.", "v."}
WORD_PATTERN = re.compile(r"^[a-z][a-z-]*$")
REQUIRED_TEXT_FIELDS = ("id", "word", "partOfSpeech", "chineseMeaning", "exampleSentence")


def load_packs(path: Path) -> list[dict[str, Any]]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ValueError(f"JSON file not found: {path}") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"Invalid JSON at line {error.lineno}, column {error.colno}: {error.msg}") from error
    if not isinstance(payload, list) or not all(isinstance(item, dict) for item in payload):
        raise ValueError("Top-level JSON value must be an array of pack objects")
    return payload


def validate(packs: list[dict[str, Any]]) -> tuple[list[str], list[str], int]:
    errors: list[str] = []
    warnings: list[str] = []
    if len(packs) != 15:
        errors.append(f"Expected 15 packs, found {len(packs)}")

    pack_ids = [str(pack.get("id", "")).strip() for pack in packs]
    for value, count in Counter(pack_ids).items():
        if not value:
            errors.append("Pack has an empty id")
        elif count > 1:
            errors.append(f"Duplicate pack id: {value}")

    expected_pack_ids = [f"ielts-pack-{index:02d}" for index in range(1, 16)]
    if pack_ids != expected_pack_ids:
        errors.append("Pack ids must be ielts-pack-01 through ielts-pack-15 in order")

    words: list[dict[str, Any]] = []
    for expected_order, pack in enumerate(packs, start=1):
        pack_words = pack.get("words")
        if not isinstance(pack_words, list):
            errors.append(f"{pack.get('id', expected_order)}: words must be an array")
            continue
        if len(pack_words) != 100:
            errors.append(f"{pack.get('id', expected_order)}: expected 100 words, found {len(pack_words)}")
        if pack.get("order") != expected_order:
            errors.append(f"{pack.get('id', expected_order)}: unexpected order {pack.get('order')}")
        words.extend(item for item in pack_words if isinstance(item, dict))

    if len(words) != 1500:
        errors.append(f"Expected 1500 words, found {len(words)}")
    ids = [str(item.get("id", "")).strip() for item in words]
    normalized_words = [str(item.get("word", "")).strip().lower() for item in words]
    for value, count in Counter(ids).items():
        if value and count > 1:
            errors.append(f"Duplicate id: {value} ({count} entries)")
        elif value and not value.startswith("ielts-"):
            errors.append(f"Non-IELTS word id: {value}")
    for value, count in Counter(normalized_words).items():
        if value and count > 1:
            errors.append(f"Duplicate word: {value} ({count} entries)")

    for index, item in enumerate(words, start=1):
        label = str(item.get("word") or item.get("id") or f"entry {index}")
        for field in REQUIRED_TEXT_FIELDS:
            value = item.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{label}: empty or invalid {field}")
        word = str(item.get("word", "")).strip()
        if word and not WORD_PATTERN.fullmatch(word):
            errors.append(f"{label}: word contains unusual characters")
        part = str(item.get("partOfSpeech", "")).strip()
        if part and part not in VALID_PARTS_OF_SPEECH:
            errors.append(f"{label}: invalid part of speech '{part}'")
        synonyms = item.get("synonyms")
        if not isinstance(synonyms, list) or not synonyms:
            errors.append(f"{label}: synonyms must be a non-empty array")
        elif not all(isinstance(value, str) and value.strip() for value in synonyms):
            errors.append(f"{label}: synonyms contain an empty or non-string value")
        elif not 2 <= len(synonyms) <= 3:
            warnings.append(f"{label}: expected 2-3 synonyms, found {len(synonyms)}")
        chinese = str(item.get("chineseMeaning", ""))
        sentence = str(item.get("exampleSentence", ""))
        if len(chinese) > 24:
            warnings.append(f"{label}: Chinese meaning is long ({len(chinese)} characters)")
        if len(sentence) > 150:
            warnings.append(f"{label}: example is long ({len(sentence)} characters)")
        if sentence and sentence[-1] not in ".!?":
            warnings.append(f"{label}: example sentence lacks terminal punctuation")
    return errors, warnings, len(words)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", type=Path, default=DEFAULT_PATH)
    args = parser.parse_args()
    try:
        packs = load_packs(args.path)
    except ValueError as error:
        print(f"ERROR: {error}")
        return 1
    errors, warnings, count = validate(packs)
    print(f"Packs: {len(packs)}")
    print(f"Total words: {count}")
    print(f"Errors: {len(errors)}")
    print(f"Warnings: {len(warnings)}")
    for message in errors:
        print(f"ERROR: {message}")
    for message in warnings:
        print(f"WARNING: {message}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
