# Changelog

All notable changes to GRE Glance are documented here.

## 1.1.4 — 2026-07-18

- Disable implicit glyph scaling and tightening for Widget words, meanings, parts of speech, and examples.
- Give every word row the same fixed height and clip overflow instead of allowing vertical layout compression.
- Migrate the legacy per-Widget Extra Large value to Comfortable while preserving a distinct new Extra Large option.
- Add regression coverage for old and new Widget text-size persistence values.

## 1.1.3 — 2026-07-18

- Use one invariant primary-text layout for every Widget row, regardless of content length.
- Restrict adaptive fallback behavior to the synonym area so long words never switch font branches.
- Adopt styled `Text` interpolation for macOS 26 compatibility.

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
