# Changelog

All notable changes to IELTS Glance are documented here.

## 2.0.2 — 2026-07-19

- Remove the unusable mixed-case App Group entitlement after confirming the macOS sandbox denied the Widget access under a Personal Team profile.
- Keep Widget Timeline generation and button App Intents in the Widget extension's own local `UserDefaults` domain, eliminating divergent state backends.
- Add independent multi-pack selection to Edit Widget so the Personal Team fallback retains full random-pool control.
- Keep transaction locking and revision guards so rapid duplicate interactions execute once.

## 2.0.1 — 2026-07-19

- Make per-word Widget replacement preserve the other four visible positions.
- Make replacement and Shuffle All interactions idempotent so rapid duplicate taps execute only once.
- Let WidgetKit perform its guaranteed post-interaction timeline reload and remove another duplicate reload during app startup.
- Stop ordinary timeline reads from rewriting unchanged display state.
- Resolve the App Group container directly so the app, Widget provider, and App Intents consistently use the same state file.

## 2.0.0 — 2026-07-19

- Rename the app, Xcode project, schemes, targets, Widget, and repository identity to IELTSGlance.
- Replace the previous vocabulary with 1,500 IELTS-tagged high-frequency, high-difficulty words in 15 selectable packs of 100.
- Rebuild the licensed offline curation pipeline, validation documentation, and attribution records for IELTS vocabulary.
- Preserve the existing Bundle Identifier and App Group so Personal Team signing and installed Widgets continue working after the rename.

## 1.1.5 — 2026-07-18

- Remove stale Widget registrations left by Xcode and validation builds before launching the current app.
- Verify that only the newly built Widget extension is registered in `--verify` mode.
- Request a Widget timeline reload whenever the newly built main app starts.

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
