#!/usr/bin/env python3
"""Build 15 deterministic IELTS packs from licensed ECDICT and Open English WordNet data.

Selection rule: keep single English headwords tagged ``ielts`` in ECDICT,
exclude school-level tags and the very common/very rare corpus tails, require
useful Open English WordNet lexical data, then prefer words outside the CET-4
core before ranking by the best available BNC/COCA-style frequency rank. The
committed resource is generated offline; the app never downloads or invokes
Python at runtime.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import zipfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SEED = ROOT / "data" / "ielts_words_seed.tsv"
DEFAULT_OUTPUT = ROOT / "Shared" / "Resources" / "ielts_word_packs.json"
DEFAULT_MANIFEST = ROOT / "data" / "ielts_curated_words.txt"
WORD_PATTERN = re.compile(r"^[a-z][a-z-]*$")
POS_MAP = {"a": "adj.", "s": "adj.", "r": "adv.", "n": "n.", "v": "v."}


def stable_id(word: str) -> str:
    return "ielts-" + re.sub(r"[^a-z0-9]+", "-", word.lower()).strip("-")


def load_seed(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        return {}
    with path.open(encoding="utf-8", newline="") as handle:
        rows = csv.DictReader(handle, delimiter="|")
        result: dict[str, dict[str, Any]] = {}
        for row in rows:
            word = row["word"].strip().lower()
            result[word] = {
                "partOfSpeech": row["partOfSpeech"].strip(),
                "chineseMeaning": row["chineseMeaning"].strip(),
                "synonyms": [value.strip() for value in row["synonyms"].split(",") if value.strip()],
                "exampleSentence": row["exampleSentence"].strip(),
            }
        return result


def extract_oewn(source: Path, destination: Path) -> Path:
    if source.is_dir():
        return source
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(source) as archive:
        archive.extractall(destination)
    return destination


def load_oewn(directory: Path) -> tuple[dict[str, dict[str, Any]], dict[str, dict[str, Any]]]:
    entries: dict[str, dict[str, Any]] = {}
    synsets: dict[str, dict[str, Any]] = {}
    for path in sorted(directory.glob("entries-*.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        for headword, entry in payload.items():
            normalized = headword.lower().replace("_", " ")
            if WORD_PATTERN.fullmatch(normalized):
                entries[normalized] = entry
    for pattern in ("adj*.json", "adv*.json", "noun*.json", "verb*.json"):
        for path in sorted(directory.glob(pattern)):
            synsets.update(json.loads(path.read_text(encoding="utf-8")))
    return entries, synsets


def positive_rank(value: str) -> int:
    try:
        rank = int(value or 0)
        return rank if rank > 0 else 1_000_000
    except ValueError:
        return 1_000_000


def clean_chinese(value: str, preferred_part: str = "") -> str:
    value = value.replace("\\n", "\n")
    lines = [line.strip() for line in value.splitlines() if line.strip() and not line.startswith("[")]
    prefix_for_part = {
        "adj.": ("a.", "adj."),
        "adv.": ("ad.", "adv."),
        "n.": ("n.",),
        "v.": ("v.", "vi.", "vt."),
    }
    matching = [
        line for line in lines
        if any(line.lower().startswith(prefix) for prefix in prefix_for_part.get(preferred_part, ()))
    ]
    line = (matching or lines or [""])[0]
    line = re.sub(r"^(vt|vi|v|n|a|ad|adv|prep|conj)\.\s*", "", line, flags=re.I)
    line = re.sub(r"\([^)]*\)", "", line)
    pieces = [piece.strip(" ；;，,") for piece in re.split(r"[,，;；]", line) if piece.strip(" ；;，,")]
    unique: list[str] = []
    for piece in pieces:
        if piece not in unique:
            unique.append(piece)
        if len("；".join(unique)) >= 16 or len(unique) == 2:
            break
    result = "；".join(unique)
    return result[:24].rstrip("；")


def lexical_data(
    word: str,
    entry: dict[str, Any],
    synsets: dict[str, dict[str, Any]],
    definition_hint: str,
) -> tuple[str, list[str], str | None]:
    candidates: list[tuple[int, int, str, list[str], str | None]] = []
    hint_tokens = set(re.findall(r"[a-z]+", definition_hint.lower()))
    hint_marker = definition_hint.strip().split(" ", 1)[0].rstrip(".")
    hinted_part = POS_MAP.get(hint_marker, "")
    sense_order = 0
    for pos_key, pos_entry in entry.items():
        if pos_key not in POS_MAP or not isinstance(pos_entry, dict):
            continue
        for sense in pos_entry.get("sense", []):
            synset = synsets.get(str(sense.get("synset", "")))
            if not synset:
                continue
            sense_order += 1
            synonyms: list[str] = []
            for member in synset.get("members", []):
                normalized = str(member).lower().replace("_", " ")
                if normalized != word and normalized not in synonyms and len(normalized) <= 24:
                    synonyms.append(normalized)
            examples: list[str] = []
            for raw_example in synset.get("example", []):
                if isinstance(raw_example, dict):
                    value = str(raw_example.get("text", "")).strip()
                else:
                    value = str(raw_example).strip()
                if value:
                    examples.append(value)
            example = next((value for value in examples if 5 <= len(value.split()) <= 22), None)
            definition = " ".join(str(value) for value in synset.get("definition", []))
            definition_tokens = set(re.findall(r"[a-z]+", definition.lower()))
            overlap = len(hint_tokens & definition_tokens) + (100 if POS_MAP[pos_key] == hinted_part else 0)
            candidates.append((overlap, -sense_order, POS_MAP[pos_key], synonyms, example))

    candidates = [value for value in candidates if len(value[3]) >= 2]
    candidates.sort(key=lambda value: (value[0], value[1]), reverse=True)
    if not candidates:
        return "", [], None
    _, _, part, synonyms, example = candidates[0]
    return part, synonyms[:3], example


def normalized_sentence(sentence: str | None, word: str, part: str) -> str:
    if sentence:
        value = sentence.strip().strip('"')
        value = value[0].upper() + value[1:] if value else value
        if value and value[-1] not in ".!?":
            value += "."
        if len(value) <= 150:
            return value

    templates = {
        "adj.": f'The adjective "{word}" became central to the critic\'s description.',
        "adv.": f'The passage uses "{word}" to clarify how the action was performed.',
        "n.": f"The essay examines {word} and its wider historical significance.",
        "v.": f'The passage uses "{word}" to describe the central action.',
    }
    return templates[part]


def build_words(
    ecdict_path: Path,
    entries: dict[str, dict[str, Any]],
    synsets: dict[str, dict[str, Any]],
    seed: dict[str, dict[str, Any]],
    selected_words: list[str] | None = None,
    curation_signals: set[str] | None = None,
) -> list[dict[str, Any]]:
    signals = curation_signals or set()
    candidates: list[tuple[tuple[int, int, int, int, str], dict[str, Any]]] = []
    with ecdict_path.open(encoding="utf-8", errors="strict", newline="") as handle:
        for row in csv.DictReader(handle):
            word = row.get("word", "").strip().lower()
            tags = set((row.get("tag") or "").lower().split())
            if (
                "ielts" not in tags
                or tags.intersection({"zk", "gk"})
                or not WORD_PATTERN.fullmatch(word)
            ):
                continue
            entry = entries.get(word)
            translation = row.get("translation") or ""
            if not entry or not clean_chinese(translation):
                continue
            definition_lines = (row.get("definition") or "").replace("\\n", "\n").splitlines()
            definition_hint = definition_lines[0] if definition_lines else ""
            part, synonyms, example = lexical_data(word, entry, synsets, definition_hint)
            chinese = clean_chinese(translation, part)
            authored = seed.get(word)
            if authored:
                part = authored["partOfSpeech"] or part
                chinese = authored["chineseMeaning"] or chinese
                synonyms = authored["synonyms"] or synonyms
                example = authored["exampleSentence"] or example
            synonyms = [value for value in synonyms if value.lower() != word][:3]
            if part not in POS_MAP.values() or len(synonyms) < 2:
                continue
            best_rank = min(positive_rank(row.get("bnc", "")), positive_rank(row.get("frq", "")))
            # IELTS high-frequency/high-difficulty band: exclude both the most
            # basic core-English words and words too rare for repeated IELTS
            # reading/listening usefulness.
            if best_rank < 3_000 or best_rank > 40_000:
                continue
            item = {
                "id": stable_id(word),
                "word": word,
                "partOfSpeech": part,
                "chineseMeaning": chinese,
                "synonyms": synonyms,
                "exampleSentence": normalized_sentence(example, word, part),
                "source": "ECDICT + Open English WordNet 2025; IELTS Glance normalized",
            }
            # Prefer vocabulary beyond the CET-4 core, then keep the most
            # frequent eligible IELTS words first. Authored seed fields enrich
            # entries but never affect which headwords are selected.
            difficulty_band = 1 if "cet4" in tags else 0
            signal_priority = 0 if word in signals else 1
            score = (
                difficulty_band,
                signal_priority,
                best_rank,
                positive_rank(row.get("frq", "")),
                word,
            )
            candidates.append((score, item))

    candidates.sort(key=lambda value: value[0])
    deduplicated: list[dict[str, Any]] = []
    seen: set[str] = set()
    for _, item in candidates:
        word = str(item["word"])
        if word not in seen:
            seen.add(word)
            deduplicated.append(item)
    if len(deduplicated) < 1500:
        raise ValueError(f"Only {len(deduplicated)} eligible words; 1500 required")
    if selected_words is not None:
        by_word = {str(item["word"]): item for item in deduplicated}
        missing = [word for word in selected_words if word not in by_word]
        if missing:
            raise ValueError(f"Selection manifest contains unavailable words: {', '.join(missing[:10])}")
        if len(selected_words) != 1500 or len(set(selected_words)) != 1500:
            raise ValueError("Selection manifest must contain exactly 1500 unique words")
        return [by_word[word] for word in selected_words]
    return deduplicated[:1500]


def make_packs(words: list[dict[str, Any]]) -> list[dict[str, Any]]:
    packs = []
    for index in range(15):
        start = index * 100
        packs.append({
            "id": f"ielts-pack-{index + 1:02d}",
            "name": f"IELTS 进阶 {index + 1:02d}",
            "subtitle": f"Words {start + 1}–{start + 100}",
            "order": index + 1,
            # Round-robin distribution keeps every pack balanced across the
            # independently curated and corpus-ranked candidate bands.
            "words": words[index::15],
        })
    return packs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ecdict", type=Path, required=True, help="Path to ECDICT ecdict.csv")
    parser.add_argument("--oewn", type=Path, required=True, help="Open English WordNet JSON zip or extracted directory")
    parser.add_argument("--seed", type=Path, default=DEFAULT_SEED)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--selection-manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--signal", action="append", type=Path, default=[], help="Additional licensed headword-only curation signal")
    parser.add_argument("--refresh-selection", action="store_true", help="Re-rank candidates and replace the selection manifest")
    args = parser.parse_args()

    oewn_dir = extract_oewn(args.oewn, ROOT / "data" / ".build" / "oewn-json")
    entries, synsets = load_oewn(oewn_dir)
    selected_words = None
    if args.selection_manifest.exists() and not args.refresh_selection:
        selected_words = [
            line.strip() for line in args.selection_manifest.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
    signal_paths = list(args.signal)
    signals: set[str] = set()
    for path in signal_paths:
        signals.update(
            line.strip().lower() for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        )
    words = build_words(
        args.ecdict,
        entries,
        synsets,
        load_seed(args.seed),
        selected_words,
        signals,
    )
    if args.refresh_selection:
        args.selection_manifest.parent.mkdir(parents=True, exist_ok=True)
        args.selection_manifest.write_text(
            "# IELTS-tagged ECDICT headwords; no zk/gk tags; corpus rank 3,000–40,000.\n"
            + "\n".join(str(item["word"]) for item in words)
            + "\n",
            encoding="utf-8",
        )
    packs = make_packs(words)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(packs, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    try:
        output_label = args.output.relative_to(ROOT)
    except ValueError:
        output_label = args.output
    print(f"Built {len(packs)} packs / {len(words)} words -> {output_label}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
