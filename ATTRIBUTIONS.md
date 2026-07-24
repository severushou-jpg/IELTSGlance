# Attributions

Vocabulary data is licensed separately from the MIT-licensed application code.

## ECDICT

- Project: [skywind3000/ECDICT](https://github.com/skywind3000/ECDICT)
- Version used for curation: commit `bc015ed2e24a7abef49fc6dbbb7fe32c1dadaf8b` (2025-03-28)
- Retrieved: 2026-07-19
- Repository license: MIT License
- Fields used: `word`, `definition`, `translation`, `tag`, `bnc`, and `frq`
- Use: IELTS-tagged candidate headwords, GRE-tagged candidate headwords, public-corpus difficulty/frequency ranking, concise Chinese gloss input, and short English definition fragments for display hints
- Modifications: excluded school-level tags and the corpus-frequency tails for IELTS, preferred words outside the CET-4 core for IELTS, selected 3000 GRE-tagged headwords after excluding school-level/CET overlap, grouped GRE into 30 topic packs of 100 words each, normalized parts of speech and Chinese punctuation, selected one or two concise glosses, and generated stable IDs

The complete upstream CSV is not committed. The app ships only the selected normalized records.

## KyleBing English Vocabulary

- Project: [KyleBing/english-vocabulary](https://github.com/KyleBing/english-vocabulary)
- Source files used: `json/3-CET4-顺序.json` and `json/4-CET6-顺序.json`
- Retrieved: 2026-07-24
- Fields used: `word`, `translations`, and `phrases`
- Use: CET-4 and CET-6 vocabulary sources for the bundled 1500-word College English Test Band 4 and Band 6 packs
- Modifications: selected the first 1500 unique CET-4 entries and first 1500 unique CET-6 entries, split each exam into 15 high/mid/low-frequency packs of 100 words each, normalized parts of speech and Chinese meanings, generated stable IDs, and added short original review-context example sentences

The complete upstream JSON files are not committed. The app ships only the selected normalized CET-4 and CET-6 records.

## Open English WordNet 2025

- Project: [Open English WordNet](https://en-word.net/)
- Source repository: [globalwordnet/english-wordnet](https://github.com/globalwordnet/english-wordnet)
- Release: `2025-edition`, `english-wordnet-2025-json.zip`
- Retrieved: 2026-07-19
- License: underlying Princeton WordNet License plus Open English WordNet additions under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- Fields used: lemma/sense links, synset part of speech, lexical sense domains, members used as synonyms, definitions used only as development-time classification context, and example sentences
- Modifications: selected the sense nearest the upstream definition hint, removed duplicate/headword synonyms, limited synonyms to two or three, normalized punctuation, used short original fallback context sentences where no suitable example existed, and grouped the frozen headwords into task/topic packs without altering their licensed lexical fields

Attribution is given to Princeton University WordNet and the Open English WordNet team as required by the upstream license.

## IELTS Glance original seed dataset

- Source: written specifically for this repository; no commercial dictionary definitions, examples, paid IELTS lists, or official test materials were copied
- Created: 2026-07-16
- License: [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
- Fields used where the headword passed the final source filters: concise Chinese meaning, two or three synonyms, and original example sentence
- Modifications: normalized lowercase headwords and stable IDs

## Application icon

- Asset: IELTS Glance App Icon
- Created: 2026-07-16 from an original project prompt
- Third-party marks: none
- Modifications: center crop and deterministic resizing for the macOS AppIcon asset catalog
- License in this repository: CC0-1.0

## Apple frameworks and symbols

SwiftUI, WidgetKit, App Intents, Foundation, and SF Symbols are system-provided and remain subject to Apple's applicable licenses and platform terms. They are not redistributed as project source assets.

No IELTS test material, Oxford, Longman, Cambridge Dictionary, Merriam-Webster, or commercial test-preparation content is bundled.
