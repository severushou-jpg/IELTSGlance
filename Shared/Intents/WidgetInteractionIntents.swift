import AppIntents
import WidgetKit

// Interactive Widget intents must be part of both the containing app and the
// Widget extension. Keeping them in Shared lets the App Intents metadata
// extractor publish the same actions from both binaries.
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
    var visibleWordIDsPayload: String

    @Parameter(title: "Selected pack IDs")
    var selectedPackIDsPayload: String

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
        self.visibleWordIDsPayload = WidgetIntentPayload.encode(visibleWordIDs)
        self.selectedPackIDsPayload = WidgetIntentPayload.encode(selectedPackIDs)
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let repository = WordRepository().load()
        let selectedPackIDs = WidgetIntentPayload.decode(selectedPackIDsPayload)
        let visibleWordIDs = WidgetIntentPayload.decode(visibleWordIDsPayload)
        let words = repository.words(selectedPackIDs: selectedPackIDs)
        _ = WordStateStore().replaceWord(
            at: position,
            expectedWordID: expectedWordID,
            expectedRevision: expectedRevision,
            displayedWordIDs: visibleWordIDs,
            words: words
        )
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
        return .result()
    }
}

struct ShuffleAllWordsIntent: AppIntent {
    static let title: LocalizedStringResource = "Shuffle all IELTS words"
    static let description = IntentDescription("Replace every visible word without recording learning history.")
    static let openAppWhenRun = false

    @Parameter(title: "Expected revision")
    var expectedRevision: Int

    @Parameter(title: "Selected pack IDs")
    var selectedPackIDsPayload: String

    init() {}

    init(expectedRevision: Int, selectedPackIDs: [String]) {
        self.expectedRevision = expectedRevision
        self.selectedPackIDsPayload = WidgetIntentPayload.encode(selectedPackIDs)
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let repository = WordRepository().load()
        let selectedPackIDs = WidgetIntentPayload.decode(selectedPackIDsPayload)
        let words = repository.words(selectedPackIDs: selectedPackIDs)
        _ = WordStateStore().shuffleAll(
            expectedRevision: expectedRevision,
            words: words
        )
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
        return .result()
    }
}

private nonisolated enum WidgetIntentPayload {
    private static let separator: Character = "|"

    static func encode(_ values: [String]) -> String {
        values.joined(separator: String(separator))
    }

    static func decode(_ payload: String) -> [String] {
        payload.split(separator: separator).map(String.init)
    }
}
