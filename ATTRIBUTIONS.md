# Attributions

Vocabulary data is licensed separately from the MIT-licensed application code.

## ECDICT

- Project: [skywind3000/ECDICT](https://github.com/skywind3000/ECDICT)
- Version used for curation: commit `bc015ed2e24a7abef49fc6dbbb7fe32c1dadaf8b` (2025-03-28)
- Retrieved: 2026-07-18
- Repository license: MIT License
- Fields used: `word`, `translation`, `tag`, `bnc`, and `frq`
- Use: candidate headwords, explicit `gre`/`ielts` exclusion, public-corpus difficulty/frequency ranking, and concise Chinese gloss input
- Modifications: removed general/IELTS-tagged candidates, applied a corpus-rank floor, normalized parts of speech and Chinese punctuation, selected one or two concise glosses, and generated stable IDs

The complete upstream CSV is not committed. The app ships only the selected normalized records.

## Open English WordNet 2025

- Project: [Open English WordNet](https://en-word.net/)
- Source repository: [globalwordnet/english-wordnet](https://github.com/globalwordnet/english-wordnet)
- Release: `2025-edition`, `english-wordnet-2025-json.zip`
- Retrieved: 2026-07-18
- License: underlying Princeton WordNet License plus Open English WordNet additions under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- Fields used: lemma/sense links, synset part of speech, members used as synonyms, and example sentences
- Modifications: selected the sense nearest the upstream definition hint, removed duplicate/headword synonyms, limited synonyms to two or three, normalized punctuation, and used short original fallback context sentences where no suitable example existed

Attribution is given to Princeton University WordNet and the Open English WordNet team as required by the upstream license.

## Last Minute Flashcards

- Project: [jaspersjsun/LastMinuteFlashcards](https://github.com/jaspersjsun/LastMinuteFlashcards)
- Retrieved: 2026-07-18
- License: MIT License, copyright (c) 2018 FakeCola
- Field used: headwords only
- Use: independent editorial prioritization signal among candidates already accepted by the ECDICT and WordNet filters
- Not used: definitions, phonetics, or other descriptive text
- Modifications: lowercased, deduplicated, and stored as `data/curation_signals/last_minute_flashcards.txt`

## GRE Glance original seed dataset

- Source: written specifically for this repository; no commercial dictionary definitions, examples, or paid GRE lists were copied
- Created: 2026-07-16
- License: [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
- Fields used where the headword passed the final source filters: concise Chinese meaning, two or three synonyms, and original example sentence
- Modifications: normalized lowercase headwords and stable IDs

## Application icon

- Asset: GRE Glance App Icon
- Created: 2026-07-16 from an original project prompt
- Third-party marks: none
- Modifications: center crop and deterministic resizing for the macOS AppIcon asset catalog
- License in this repository: CC0-1.0

## Apple frameworks and symbols

SwiftUI, WidgetKit, App Intents, Foundation, and SF Symbols are system-provided and remain subject to Apple's applicable licenses and platform terms. They are not redistributed as project source assets.

No Oxford, Longman, Cambridge, Merriam-Webster, ETS, GregMat, Magoosh, or other commercial dictionary/test-preparation content is bundled.
