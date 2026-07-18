#!/usr/bin/env python3
"""Extract headword-only signals from licensed upstream development sources."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

WORD = re.compile(r"^[a-z][a-z-]*$")


def extract_lmf(directory: Path) -> list[str]:
    words: set[str] = set()
    for path in sorted(directory.glob("List*.txt")):
        lines = path.read_text(encoding="utf-8").splitlines()
        for index, line in enumerate(lines[:-1]):
            candidate = line.strip().lower()
            if WORD.fullmatch(candidate) and lines[index + 1].lstrip().startswith("/"):
                words.add(candidate)
    return sorted(words)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--last-minute-flashcards", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    words = extract_lmf(args.last_minute_flashcards)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        "# Headword-only curation signal from jaspersjsun/LastMinuteFlashcards (MIT).\n"
        + "\n".join(words)
        + "\n",
        encoding="utf-8",
    )
    print(f"Extracted {len(words)} headwords -> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
