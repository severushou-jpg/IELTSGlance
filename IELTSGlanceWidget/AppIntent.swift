//
//  AppIntent.swift
//  IELTSGlanceWidget
//
//  Created by severushou on 2026/7/16.
//

import AppIntents

enum WidgetVocabularyPack: String, AppEnum, CaseIterable {
    case pack01 = "ielts-pack-01"
    case pack02 = "ielts-pack-02"
    case pack03 = "ielts-pack-03"
    case pack04 = "ielts-pack-04"
    case pack05 = "ielts-pack-05"
    case pack06 = "ielts-pack-06"
    case pack07 = "ielts-pack-07"
    case pack08 = "ielts-pack-08"
    case pack09 = "ielts-pack-09"
    case pack10 = "ielts-pack-10"
    case pack11 = "ielts-pack-11"
    case pack12 = "ielts-pack-12"
    case pack13 = "ielts-pack-13"
    case pack14 = "ielts-pack-14"
    case pack15 = "ielts-pack-15"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "IELTS word pack"
    static let caseDisplayRepresentations: [WidgetVocabularyPack: DisplayRepresentation] = [
        .pack01: "IELTS 进阶 01 · Words 1–100",
        .pack02: "IELTS 进阶 02 · Words 101–200",
        .pack03: "IELTS 进阶 03 · Words 201–300",
        .pack04: "IELTS 进阶 04 · Words 301–400",
        .pack05: "IELTS 进阶 05 · Words 401–500",
        .pack06: "IELTS 进阶 06 · Words 501–600",
        .pack07: "IELTS 进阶 07 · Words 601–700",
        .pack08: "IELTS 进阶 08 · Words 701–800",
        .pack09: "IELTS 进阶 09 · Words 801–900",
        .pack10: "IELTS 进阶 10 · Words 901–1000",
        .pack11: "IELTS 进阶 11 · Words 1001–1100",
        .pack12: "IELTS 进阶 12 · Words 1101–1200",
        .pack13: "IELTS 进阶 13 · Words 1201–1300",
        .pack14: "IELTS 进阶 14 · Words 1301–1400",
        .pack15: "IELTS 进阶 15 · Words 1401–1500"
    ]
}

struct ReplaceWordIntent: AppIntent {
    static let title: LocalizedStringResource = "Replace IELTS word"
    static let description = IntentDescription("Replace one visible word without recording learning history.")
    static let openAppWhenRun = false

    @Parameter(title: "Position")
    var position: Int

    @Parameter(title: "Expected word ID")
    var expectedWordID: String

    @Parameter(title: "Expected revision")
    var expectedRevision: Int

    @Parameter(title: "Visible word IDs")
    var visibleWordIDs: [String]

    @Parameter(title: "Selected pack IDs")
    var selectedPackIDs: [String]

    init() {}

    init(
        position: Int,
        expectedWordID: String,
        expectedRevision: Int,
        visibleWordIDs: [String],
        selectedPackIDs: [String]
    ) {
        self.position = position
        self.expectedWordID = expectedWordID
        self.expectedRevision = expectedRevision
        self.visibleWordIDs = visibleWordIDs
        self.selectedPackIDs = selectedPackIDs
    }

    func perform() async throws -> some IntentResult {
        let repository = WordRepository().load()
        let words = repository.words(selectedPackIDs: selectedPackIDs)
        _ = WordStateStore().replaceWord(
            at: position,
            expectedWordID: expectedWordID,
            expectedRevision: expectedRevision,
            displayedWordIDs: visibleWordIDs,
            words: words
        )
        return .result()
    }
}

struct ShuffleAllWordsIntent: AppIntent {
    static let title: LocalizedStringResource = "Shuffle all IELTS words"
    static let description = IntentDescription("Replace all five visible words without recording learning history.")
    static let openAppWhenRun = false

    @Parameter(title: "Expected revision")
    var expectedRevision: Int

    @Parameter(title: "Selected pack IDs")
    var selectedPackIDs: [String]

    init() {}

    init(expectedRevision: Int, selectedPackIDs: [String]) {
        self.expectedRevision = expectedRevision
        self.selectedPackIDs = selectedPackIDs
    }

    func perform() async throws -> some IntentResult {
        let repository = WordRepository().load()
        let words = repository.words(selectedPackIDs: selectedPackIDs)
        _ = WordStateStore().shuffleAll(
            expectedRevision: expectedRevision,
            words: words
        )
        return .result()
    }
}
