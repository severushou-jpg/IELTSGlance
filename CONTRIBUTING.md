# Contributing to GRE Glance

Thanks for considering a contribution. GRE Glance is intentionally small: it is an offline, glance-first vocabulary tool rather than a flashcard scheduler or learning tracker.

## Before opening a change

- Discuss substantial product changes in an issue first.
- Keep the app native to Swift, SwiftUI, WidgetKit, and App Intents.
- Do not add accounts, analytics, network dependencies, mastery history, streaks, or spaced repetition.
- Do not copy commercial dictionaries, paid GRE lists, or data with unclear redistribution rights.
- Record the source and license of any vocabulary contribution in `ATTRIBUTIONS.md`.

## Local validation

Run these checks before submitting a pull request:

```bash
python3 scripts/validate_words.py

swiftc -parse-as-library \
  Shared/Models/GREWord.swift \
  Shared/Models/WidgetDisplayState.swift \
  Shared/Support/SharedConstants.swift \
  Shared/Services/RandomWordPicker.swift \
  Shared/Stores/WordStateStore.swift \
  scripts/verify_state_logic.swift \
  -framework Security \
  -o /tmp/verify_gre_glance_state
/tmp/verify_gre_glance_state

xcodebuild -project GREGlance.xcodeproj \
  -scheme GREGlance \
  -configuration Debug \
  -destination "platform=macOS" \
  build
```

If your Personal Team cannot provision App Groups, follow the documented fallback in `README.md` rather than committing personal signing changes.

## Pull requests

Keep each pull request focused. Explain the user-facing impact, include screenshots for visual changes, and describe every validation command you ran. By contributing code, you agree that it may be distributed under the repository's MIT License. Vocabulary data retains the license documented for its source.
