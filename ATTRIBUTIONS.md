# Attributions

## Development vocabulary dataset

- Project: GRE Glance original development dataset
- Source: Written specifically for this repository; no commercial dictionary definitions, examples, or paid GRE lists were copied.
- License: [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
- Obtained/created: 2026-07-16
- Fields used: headword, abbreviated part of speech, concise Chinese meaning, two or three English synonyms, and an original example sentence
- Modifications: normalized lowercase headwords, generated stable `gre-<word>` identifiers, sorted entries, and serialized the seed TSV as JSON
- Current entry count: 337

The vocabulary words themselves are ordinary language facts. The project's concise meanings and example sentences are released separately from the application code under CC0-1.0 so that a later, fully licensed dataset can replace them cleanly.

No Oxford, Longman, Cambridge, Merriam-Webster, ETS, GregMat, Magoosh, or other commercial dictionary/test-preparation content is bundled.

## Application icon

- Asset: GRE Glance App Icon
- Created: 2026-07-16 with OpenAI's built-in image generation tool from an original project prompt
- Third-party marks: none
- Modifications: center crop and deterministic resizing for the macOS AppIcon asset catalog
- License in this repository: CC0-1.0

## Apple frameworks and symbols

The application uses system-provided SwiftUI, WidgetKit, App Intents, Foundation, and SF Symbols at runtime. These frameworks and symbols remain subject to Apple's applicable licenses and platform terms; they are not redistributed as project source assets.
