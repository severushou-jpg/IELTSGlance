# Contributing to IELTS Glance

Thanks for considering a contribution. IELTS Glance is intentionally small: it is an offline, glance-first vocabulary tool rather than a flashcard scheduler or learning tracker.

## Before opening a change

- Discuss substantial product changes in an issue first.
- Keep the app native to Swift, SwiftUI, WidgetKit, and App Intents.
- Do not add accounts, analytics, network dependencies, mastery history, streaks, or spaced repetition.
- Do not copy commercial dictionaries, paid IELTS lists, official test materials, or data with unclear redistribution rights.
- Record the source and license of any vocabulary contribution in `ATTRIBUTIONS.md`.

## Local validation

Run these checks before submitting a pull request:

```bash
python3 scripts/validate_words.py

xcodebuild -project IELTSGlance.xcodeproj \
  -scheme IELTSGlance \
  -configuration Debug \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  test
```

The project intentionally uses the Personal Team local-storage mode documented in `README.md`; do not add personal signing identifiers or App Group entitlements to a contribution.

## Pull requests

Keep each pull request focused. Explain the user-facing impact, include screenshots for visual changes, and describe every validation command you ran. By contributing code, you agree that it may be distributed under the repository's MIT License. Vocabulary data retains the license documented for its source.
