# Changelog

All notable changes to GRE Glance are documented here.

## 1.1.2 — 2026-07-18

- Render the word, part of speech, and Chinese meaning as one styled text run so every Widget row uses identical font metrics.
- Keep the part of speech on the same line instead of allowing narrow fallback rows to compress it vertically.

## 1.1.1 — 2026-07-18

- Keep every Widget word and Chinese meaning at a consistent visual size.
- Remove synonyms progressively before truncating primary text in narrow rows.
- Migrate the previous oversized default to the balanced comfortable size without changing selected packs.

## 1.1.0 — 2026-07-18

- Expand the offline vocabulary to 1,500 curated words in 15 selectable packs.
- Share pack selection, text-size defaults, and synonym count between the app and Widget.
- Add per-Widget text-size configuration with App Intents.
- Make Widget rows adapt synonyms before shrinking the primary word and Chinese meaning.
- Move display state to atomically written, cross-process locked local storage.
- Add a native Settings window and richer pack-aware app preview.
- Add formal unit tests and stricter data validation.

## 1.0.0 — 2026-07-16

- Initial native macOS app and interactive large Widget.
