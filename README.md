# GRE Glance

[![CI](https://github.com/severushou-jpg/GRE-Glance/actions/workflows/ci.yml/badge.svg)](https://github.com/severushou-jpg/GRE-Glance/actions/workflows/ci.yml)
![Platform](https://img.shields.io/badge/platform-macOS%2026.2%2B-000000?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white)
[![License: MIT](https://img.shields.io/badge/code%20license-MIT-blue.svg)](LICENSE)

GRE Glance is a quiet, completely offline macOS app and desktop Widget for repeated exposure to challenging GRE vocabulary. It is not a flashcard scheduler, test, streak tracker, or spaced-repetition system. A checkmark simply means “show another word”; no mastery status or learning history is created.

![GRE Glance large Widget](docs/gre-glance-widget.png)

## What is included

- 1,500 locally bundled words split into exactly 15 balanced packs of 100
- Any one pack or any combination of packs can define the random pool
- Five distinct words in a native `.systemLarge` macOS Widget
- Per-word replacement and `Shuffle All` using App Intents
- Per-Widget text-size choice plus an App-wide default
- Responsive synonym layout that yields space before shrinking the word or Chinese meaning
- Stable `.never` timelines; ordinary redraws do not change the five words
- Atomic, cross-process locked technical state shared by the App and Widget
- Native Settings window, `⌘R`, semantic Light/Dark Mode colors, and VoiceOver labels
- No login, server, analytics, ads, API key, AI service, or network request

## Requirements

- macOS 26.2 or later
- Xcode 26.2 or a compatible newer Xcode
- A selected Apple Development team when running the Widget extension

The implementation uses APIs available from macOS 14 onward, but the repository deliberately preserves the existing project's higher macOS 26.2 deployment target.

## Build, test, and run

Open `GREGlance.xcodeproj`, select the `GREGlance` scheme, and run on **My Mac**, or use:

```bash
python3 scripts/validate_words.py

xcodebuild \
  -project GREGlance.xcodeproj \
  -scheme GREGlance \
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
3. Search for **GRE Glance** / 搜索“GRE Glance”。
4. Select the large size and add it / 选择大号尺寸并添加。

Right-click the Widget and choose **Edit “GRE Glance”** to select Comfortable, Large, Extra Large, or Follow App Setting. Pack selection is global and lives in the main app so every Widget uses the same intended study pool.

## Vocabulary curation

The shipped dataset has **1,500 entries in 15 packs of 100**. It is a transparent editorial approximation of “GRE-frequent and harder than IELTS,” not an official ETS frequency list:

1. Start with ECDICT headwords tagged `gre` and exclude every headword tagged `ielts`.
2. Exclude the very common corpus band by requiring a published ECDICT BNC/frequency rank of at least 12,000.
3. Require usable lexical data from Open English WordNet.
4. Prioritize the project's manually authored seed and headwords independently present in the MIT-licensed Last Minute Flashcards GRE list.
5. Rank the remaining eligible candidates by corpus frequency, freeze the exact 1,500-word selection in `data/curated_words.txt`, and distribute the ranking bands round-robin so all 15 packs are balanced.

This method intentionally avoids Oxford, Cambridge, Longman, Merriam-Webster, ETS, and commercial preparation-company datasets. See [ATTRIBUTIONS.md](ATTRIBUTIONS.md) for exact versions, fields, modifications, and licenses.

The primary resource is `Shared/Resources/gre_word_packs.json`:

```json
[
  {
    "id": "gre-pack-01",
    "name": "GRE 进阶 01",
    "subtitle": "Words 1–100",
    "order": 1,
    "words": [
      {
        "id": "gre-proliferate",
        "word": "proliferate",
        "partOfSpeech": "v.",
        "chineseMeaning": "迅速增多",
        "synonyms": ["multiply", "spread", "burgeon"],
        "exampleSentence": "Unverified copies of the document began to proliferate online.",
        "source": "ECDICT + Open English WordNet 2025; GRE Glance normalized"
      }
    ]
  }
]
```

The runtime accepts any valid pack resource without code changes. To rebuild from the same upstream formats, download ECDICT's `ecdict.csv` and the Open English WordNet 2025 JSON release, then run:

```bash
python3 scripts/build_curated_packs.py \
  --ecdict /path/to/ecdict.csv \
  --oewn /path/to/english-wordnet-2025-json.zip

python3 scripts/validate_words.py
```

The committed selection manifest makes subsequent builds use the same 1,500 headwords. Pass `--refresh-selection` only for an intentional, reviewed vocabulary release. Python is a development tool only; the App and Widget never invoke it.

## Data and code licenses

- Swift code and development scripts: MIT License; see [LICENSE](LICENSE).
- ECDICT-derived selection, corpus ranks, and concise Chinese glosses: ECDICT repository MIT license.
- Open English WordNet synonyms, parts of speech, and examples: WordNet License plus CC BY 4.0.
- Last Minute Flashcards headword-only curation signal: MIT License.
- GRE Glance original seed fields and icon: CC0-1.0.

These data terms are separate from the code license. Do not assume that replacing the JSON automatically makes the replacement data MIT-licensed.

## State, privacy, and concurrency

The app persists only the current five word IDs, a technical revision/timestamp, selected pack IDs, and display preferences. These values exist solely to keep redraws stable and honor the user's chosen random pool. They are not learning records.

State is stored as atomically replaced JSON in the shared App Group container and guarded with a `flock` lock so rapid App/Widget actions cannot overwrite each other. Corrupt or obsolete values are repaired from the active word pool without crashing.

The app does not save answers, mastered words, streaks, review history, behavioral analytics, or personal information. All data remains on the Mac.

## App Group and Personal Team fallback

This checkout currently provisions both targets with the existing identifier:

```text
group.com.bingxuhou.GREGlance.shared
```

It is held in one `APP_GROUP_IDENTIFIER` build setting and expanded into both entitlements. The first command-line provisioning build can require:

```bash
xcodebuild -allowProvisioningUpdates \
  -project GREGlance.xcodeproj \
  -scheme GREGlance \
  -destination "platform=macOS" \
  build
```

If another free Personal Team cannot provision App Groups, remove the App Groups capability/entitlement from both targets. The code detects the signed entitlement and falls back to each target's local storage. The Widget remains fully functional; only immediate App/Widget state and preference synchronization is unavailable, and the App reports the independent mode. A paid membership is not required for the fallback MVP.

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

GRE is a registered trademark of ETS. This project is an independent study tool and is not affiliated with or endorsed by ETS.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Report security issues through the process in [SECURITY.md](SECURITY.md).
