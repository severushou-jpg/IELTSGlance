# IELTS Glance

[![CI](https://github.com/severushou-jpg/IELTSGlance/actions/workflows/ci.yml/badge.svg)](https://github.com/severushou-jpg/IELTSGlance/actions/workflows/ci.yml)
![Platform](https://img.shields.io/badge/platform-macOS%2026.2%2B-000000?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white)
[![License: MIT](https://img.shields.io/badge/code%20license-MIT-blue.svg)](LICENSE)

IELTS Glance is a quiet, completely offline macOS app and desktop Widget for repeated exposure to high-frequency, challenging IELTS vocabulary. It is not a flashcard scheduler, test, streak tracker, or spaced-repetition system. A checkmark simply means “show another word”; no mastery status or learning history is created.

## What is included

- 1,500 locally bundled words split into exactly 15 balanced packs of 100
- Any one pack or any combination of packs can define the random pool
- Five distinct words in a native `.systemLarge` macOS Widget
- Per-word replacement and `Shuffle All` using App Intents
- Independent text-size and pack selection for the Widget and app preview
- Responsive synonym layout that yields space before shrinking the word or Chinese meaning
- Stable `.never` timelines; ordinary redraws do not change the five words
- Stable revision-guarded local technical state for the App and Widget
- Native Settings window, `⌘R`, semantic Light/Dark Mode colors, and VoiceOver labels
- No login, server, analytics, ads, API key, AI service, or network request

## Requirements

- macOS 26.2 or later
- Xcode 26.2 or a compatible newer Xcode
- A selected Apple Development team when running the Widget extension

The implementation uses APIs available from macOS 14 onward, but the repository deliberately preserves the existing project's higher macOS 26.2 deployment target.

## Build, test, and run

Open `IELTSGlance.xcodeproj`, select the `IELTSGlance` scheme, and run on **My Mac**, or use:

```bash
python3 scripts/validate_words.py

xcodebuild \
  -project IELTSGlance.xcodeproj \
  -scheme IELTSGlance \
  -configuration Debug \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  test

./script/build_and_run.sh --verify
```

`build_and_run.sh` discovers the project and main scheme, stops an existing process, builds with the project's signing settings, finds the generated `.app`, and launches it with `/usr/bin/open -n`. Build output stays under ignored `.build/`.

## Add and configure the Widget

1. Right-click an empty area of the desktop / 在桌面空白处右键。
2. Choose **Edit Widgets** / 选择“编辑小组件”。
3. Search for **IELTS Glance** / 搜索“IELTS Glance”。
4. Select the large size and add it / 选择大号尺寸并添加。

Right-click the Widget and choose **Edit “IELTS Glance”** to select Comfortable, Large, Extra Large, or Follow App Setting. Pack selection is global and lives in the main app so every Widget uses the same intended study pool.

## Vocabulary curation

The shipped dataset has **1,500 entries in 15 packs of 100**. It is a transparent editorial approximation of frequently useful, upper-intermediate-to-advanced IELTS vocabulary—not an official IELTS frequency list:

1. Start with single English ECDICT headwords explicitly tagged `ielts`.
2. Exclude entries carrying the `zk` or `gk` school-level tags.
3. Keep a practical BNC/contemporary-corpus rank band of 3,000–40,000, excluding both very basic core words and extremely rare words.
4. Require usable Open English WordNet lexical data, including a valid part of speech and at least two synonyms.
5. Prefer words outside the CET-4 core, rank eligible words by corpus frequency, freeze the exact 1,500 headwords in `data/ielts_curated_words.txt`, and distribute ranking bands round-robin so every pack remains balanced.

This method intentionally avoids IELTS test materials, Oxford, Cambridge Dictionary, Longman, Merriam-Webster, and commercial preparation-company datasets. See [ATTRIBUTIONS.md](ATTRIBUTIONS.md) for exact versions, fields, modifications, and licenses.

The primary resource is `Shared/Resources/ielts_word_packs.json`:

```json
[
  {
    "id": "ielts-pack-01",
    "name": "IELTS 进阶 01",
    "subtitle": "Words 1–100",
    "order": 1,
    "words": [
      {
        "id": "ielts-volatile",
        "word": "volatile",
        "partOfSpeech": "adj.",
        "chineseMeaning": "易变的；不稳定的",
        "synonyms": ["unstable", "explosive", "changeable"],
        "exampleSentence": "Prices remained volatile after the unexpected announcement.",
        "source": "ECDICT + Open English WordNet 2025; IELTS Glance normalized"
      }
    ]
  }
]
```

The runtime accepts any valid pack resource without code changes. To rebuild from the same upstream formats, download ECDICT's `ecdict.csv` and the Open English WordNet 2025 JSON release, then run:

```bash
python3 scripts/build_ielts_packs.py \
  --ecdict /path/to/ecdict.csv \
  --oewn /path/to/english-wordnet-2025-json.zip

python3 scripts/validate_words.py
```

The committed selection manifest makes subsequent builds use the same 1,500 headwords. Pass `--refresh-selection` only for an intentional, reviewed vocabulary release. Python is a development tool only; the App and Widget never invoke it.

## Data and code licenses

- Swift code and development scripts: MIT License; see [LICENSE](LICENSE).
- ECDICT-derived selection, corpus ranks, and concise Chinese glosses: ECDICT repository MIT license.
- Open English WordNet synonyms, parts of speech, and examples: WordNet License plus CC BY 4.0.
- IELTS Glance original seed fields and icon: CC0-1.0.

These data terms are separate from the code license. Do not assume that replacing the JSON automatically makes the replacement data MIT-licensed.

## State, privacy, and concurrency

The app persists only the current five word IDs, a technical revision/timestamp, selected pack IDs, and display preferences. These values exist solely to keep redraws stable and honor the user's chosen random pool. They are not learning records.

State is stored in each target's local `UserDefaults` domain and guarded by a revision check plus a local transaction lock. Corrupt or obsolete values are repaired from the active word pool without crashing. The Widget's pack selection is part of its own Widget configuration, so it does not depend on the main app being open.

The app does not save answers, mastered words, streaks, review history, behavioral analytics, or personal information. All data remains on the Mac.

## Personal Team storage mode

This checkout uses the reliable Personal Team fallback: the app preview and Widget keep independent local technical state, with no App Group entitlement required. This avoids provisioning and sandbox failures on free developer profiles. The Widget remains fully functional and lets users select one or several packs through **Edit Widget**. No paid membership is required.

## FAQ

**Does the checkmark mean “mastered”?**

No. It only replaces that position and records no learning history.

**Why did words change when I changed packs?**

Changing the selected packs intentionally rebuilds the five-word technical state so every visible word belongs to the new pool. Ordinary redraws remain stable.

**Can users import their own lists?**

Not in this release. The resource architecture supports replacement data, but a safe user-facing importer and validation UI are deliberately deferred.

**Does it need the terminal or internet after launch?**

No. Both targets run normally from the built app and all vocabulary is bundled locally.

## Trademark notice

IELTS and its logos are trade marks of the IELTS Partners. IELTS Glance is an independent study tool and is not affiliated with, approved by, or endorsed by the British Council, IDP IELTS, or Cambridge University Press & Assessment. No official IELTS test content or branding is included. See the [official IELTS trade mark statement](https://ielts.org/legal/ielts-copyright-and-trade-mark-statement).

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Report security issues through the process in [SECURITY.md](SECURITY.md).
