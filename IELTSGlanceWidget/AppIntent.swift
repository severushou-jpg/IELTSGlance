//
//  AppIntent.swift
//  IELTSGlanceWidget
//
//  Created by severushou on 2026/7/16.
//

import AppIntents
import WidgetKit

struct ReplaceWordIntent: AppIntent {
    static let title: LocalizedStringResource = "Replace IELTS word"
    static let description = IntentDescription("Replace one visible word without recording learning history.")
    static let openAppWhenRun = false

    @Parameter(title: "Position")
    var position: Int

    @Parameter(title: "Expected word ID")
    var expectedWordID: String

    init() {}

    init(position: Int, expectedWordID: String) {
        self.position = position
        self.expectedWordID = expectedWordID
    }

    func perform() async throws -> some IntentResult {
        let repository = WordRepository().load()
        let preferences = SharedPreferencesStore().load(availablePackIDs: repository.packIDs)
        let words = repository.words(selectedPackIDs: preferences.selectedPackIDs)
        _ = WordStateStore().replaceWord(
            at: position,
            expectedWordID: expectedWordID,
            words: words
        )
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
        return .result()
    }
}

struct ShuffleAllWordsIntent: AppIntent {
    static let title: LocalizedStringResource = "Shuffle all IELTS words"
    static let description = IntentDescription("Replace all five visible words without recording learning history.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        let repository = WordRepository().load()
        let preferences = SharedPreferencesStore().load(availablePackIDs: repository.packIDs)
        let words = repository.words(selectedPackIDs: preferences.selectedPackIDs)
        _ = WordStateStore().shuffleAll(words: words)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
        return .result()
    }
}
