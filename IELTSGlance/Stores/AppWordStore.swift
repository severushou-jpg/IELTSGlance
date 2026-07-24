import Foundation
import Observation
import WidgetKit

struct ExamSelectionOption: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let isAvailable: Bool
}

@Observable
@MainActor
final class AppWordStore {
    private let stateStore: WordStateStore
    private let preferencesStore: SharedPreferencesStore
    private let learningProgressStore: VocabularyLearningProgressStore
    private let snapshot: WordRepositorySnapshot

    private(set) var displayedWords: [IELTSWord] = []
    private(set) var issue: String?
    private(set) var preferences: IELTSGlancePreferences
    var studyMode: AppStudyMode = .glance
    var sprintRoundTarget: Int = 3
    var sprintPalette: SprintAccentPalette = .fresh
    private(set) var sprintPackStates: [String: SprintPackState] = [:]
    private(set) var activeSprintPackID: String?

    init() {
        let repository = WordRepository()
        snapshot = repository.load()
        stateStore = WordStateStore()
        preferencesStore = SharedPreferencesStore()
        learningProgressStore = VocabularyLearningProgressStore()
        preferences = preferencesStore.load(
            availableExamIDs: snapshot.examIDs,
            defaultExamID: snapshot.defaultExam?.id,
            availablePackIDs: snapshot.packIDs
        )
        issue = snapshot.issue
        reloadFromPersistence()
        resetSprintSession()
    }

    var totalWordCount: Int { snapshot.words.count }
    var exams: [VocabularyExam] { snapshot.exams }
    var selectedExam: VocabularyExam? { snapshot.exam(id: selectedExamID) }
    var selectedExamID: String { preferences.selectedExamID ?? snapshot.defaultExam?.id ?? "" }
    var examSelectionOptions: [ExamSelectionOption] {
        [
            ExamSelectionOption(id: "cet4", title: "四级", isAvailable: snapshot.examIDs.contains("cet4")),
            ExamSelectionOption(id: "cet6", title: "六级", isAvailable: snapshot.examIDs.contains("cet6")),
            ExamSelectionOption(id: SharedConstants.legacyIELTSExamID, title: "雅思", isAvailable: snapshot.examIDs.contains(SharedConstants.legacyIELTSExamID)),
            ExamSelectionOption(id: "gre", title: "GRE", isAvailable: snapshot.examIDs.contains("gre"))
        ]
    }
    var packs: [VocabularyPack] { snapshot.packs(selectedExamID: selectedExamID) }
    var selectedPackIDs: Set<String> { Set(preferences.selectedPackIDs) }
    var selectedWordCount: Int { selectedWords.count }
    var defaultTextSize: WidgetTextSize { preferences.defaultTextSize }
    var synonymLimit: Int { preferences.synonymLimit }
    var usesFallbackData: Bool { snapshot.isUsingFallback }
    var usesSharedState: Bool { SharedConstants.usesAppGroup }
    var stateModeDescription: String { SharedConstants.stateModeDescription }
    var sprintRoundOptions: [Int] { Array(1...5) }

    var activeSprintPack: VocabularyPack? {
        guard let activeSprintPackID else { return packs.first }
        return packs.first { $0.id == activeSprintPackID }
    }

    var activeSprintState: SprintPackState? {
        guard let packID = activeSprintPack?.id else { return nil }
        return sprintPackStates[packID]
    }

    var sprintDisplayedWords: [IELTSWord] {
        guard let pack = activeSprintPack,
              var state = sprintPackStates[pack.id] else {
            return []
        }
        let visibleIDs = state.visibleWordIDs(count: SharedConstants.displayedWordCount)
        let wordsByID = Dictionary(pack.words.map { ($0.id, $0) }, uniquingKeysWith: { existing, _ in existing })
        return visibleIDs.compactMap { wordsByID[$0] }
    }

    var reviewLaterWords: [IELTSWord] {
        let progress = learningProgressStore.load()
        var reviewLaterIDs = Set(progress.recordsByWordID.values.compactMap { record in
            record.status == .reviewLater ? record.wordID : nil
        })
        sprintPackStates.values.forEach { state in
            reviewLaterIDs.formUnion(state.reviewLaterWordIDs)
        }
        return snapshot.allWords.filter { reviewLaterIDs.contains($0.id) }
    }

    var reviewLaterCount: Int {
        reviewLaterWords.count
    }

    func reloadFromPersistence() {
        preferences = preferencesStore.load(
            availableExamIDs: snapshot.examIDs,
            defaultExamID: snapshot.defaultExam?.id,
            availablePackIDs: availablePackIDsForSelectedExam
        )
        let words = selectedWords
        let state = stateStore.currentState(words: words)
        displayedWords = stateStore.words(for: state, in: words)
        ensureSprintSelectionIsAvailable()
    }

    func setStudyMode(_ mode: AppStudyMode) {
        studyMode = mode
    }

    func setSelectedExam(_ examID: String) {
        guard snapshot.examIDs.contains(examID), examID != selectedExamID else { return }
        let packIDs = snapshot.packIDs(selectedExamID: examID)
        updatePreferences(
            selectedExamID: examID,
            availablePackIDs: packIDs
        ) {
            $0.selectedExamID = examID
            $0.selectedPackIDs = Array(packIDs.prefix(1))
        }
        shuffleAll()
        resetSprintSession()
    }

    func replaceWord(at position: Int) {
        guard displayedWords.indices.contains(position) else { return }
        _ = learningProgressStore.recordSeen(wordID: displayedWords[position].id)
        let state = stateStore.replaceWord(
            at: position,
            expectedWordID: displayedWords[position].id,
            words: selectedWords
        )
        displayedWords = stateStore.words(for: state, in: selectedWords)
        reloadWidgetIfNeeded()
    }

    func shuffleAll() {
        let words = selectedWords
        displayedWords.forEach { _ = learningProgressStore.recordSeen(wordID: $0.id) }
        let state = stateStore.shuffleAll(words: words)
        displayedWords = stateStore.words(for: state, in: words)
        reloadWidgetIfNeeded()
    }

    func togglePack(_ packID: String) {
        var selected = selectedPackIDs
        if selected.contains(packID) {
            guard selected.count > 1 else { return }
            selected.remove(packID)
        } else {
            selected.insert(packID)
        }
        updatePreferences { $0.selectedPackIDs = availablePackIDsForSelectedExam.filter(selected.contains) }
        shuffleAll()
        resetSprintSession()
    }

    func selectAllPacks() {
        updatePreferences { $0.selectedPackIDs = availablePackIDsForSelectedExam }
        shuffleAll()
        resetSprintSession()
    }

    func selectOnlyPack(_ packID: String) {
        guard availablePackIDsForSelectedExam.contains(packID) else { return }
        updatePreferences { $0.selectedPackIDs = [packID] }
        shuffleAll()
        resetSprintSession()
    }

    func setDefaultTextSize(_ size: WidgetTextSize) {
        guard WidgetTextSize.appSelectableCases.contains(size) else { return }
        updatePreferences { $0.defaultTextSize = size }
        reloadWidgetIfNeeded()
    }

    func setSynonymLimit(_ limit: Int) {
        updatePreferences { $0.synonymLimit = min(max(limit, 1), 3) }
        reloadWidgetIfNeeded()
    }

    func setSprintRoundTarget(_ rounds: Int) {
        sprintRoundTarget = min(max(rounds, 1), 5)
        resetSprintSession()
    }

    func setSprintPalette(_ palette: SprintAccentPalette) {
        sprintPalette = palette
    }

    func selectSprintPack(_ packID: String) {
        guard selectedPackIDs.contains(packID) else { return }
        activeSprintPackID = packID
    }

    func resetSprintSession() {
        var states: [String: SprintPackState] = [:]
        for pack in packs where selectedPackIDs.contains(pack.id) {
            states[pack.id] = SprintPackState(
                packID: pack.id,
                wordIDs: pack.words.map(\.id),
                targetRounds: sprintRoundTarget
            )
        }
        sprintPackStates = states
        activeSprintPackID = activeSprintPackID.flatMap { states[$0] == nil ? nil : $0 }
            ?? preferences.selectedPackIDs.first
    }

    func advanceSprintBatch() {
        guard let pack = activeSprintPack,
              var state = sprintPackStates[pack.id] else {
            return
        }
        let visibleCount = sprintDisplayedWords.count
        sprintDisplayedWords.forEach { _ = learningProgressStore.recordSeen(wordID: $0.id) }
        state.advance(count: visibleCount, allWordIDs: pack.words.map(\.id))
        sprintPackStates[pack.id] = state
    }

    func toggleSprintReviewLater(_ wordID: String) {
        guard let packID = activeSprintPack?.id,
              var state = sprintPackStates[packID] else {
            return
        }
        if state.reviewLaterWordIDs.contains(wordID) {
            _ = learningProgressStore.clearStatus(.reviewLater, wordID: wordID)
            state.unmarkReviewLater(wordID: wordID)
        } else {
            _ = learningProgressStore.setStatus(.reviewLater, wordID: wordID)
            state.markReviewLater(wordID: wordID)
        }
        sprintPackStates[packID] = state
    }

    func removeReviewLater(_ wordID: String) {
        _ = learningProgressStore.clearStatus(.reviewLater, wordID: wordID)
        for packID in sprintPackStates.keys {
            sprintPackStates[packID]?.unmarkReviewLater(wordID: wordID)
        }
    }

    private var selectedWords: [IELTSWord] {
        snapshot.words(selectedExamID: selectedExamID, selectedPackIDs: preferences.selectedPackIDs)
    }

    private var availablePackIDsForSelectedExam: [String] {
        snapshot.packIDs(selectedExamID: selectedExamID)
    }

    private func ensureSprintSelectionIsAvailable() {
        if sprintPackStates.isEmpty {
            resetSprintSession()
        } else if let activeSprintPackID, sprintPackStates[activeSprintPackID] != nil {
            return
        } else {
            activeSprintPackID = preferences.selectedPackIDs.first
        }
    }

    private func updatePreferences(
        selectedExamID: String? = nil,
        availablePackIDs: [String]? = nil,
        _ transform: (inout IELTSGlancePreferences) -> Void
    ) {
        let examID = selectedExamID ?? self.selectedExamID
        preferences = preferencesStore.update(
            availableExamIDs: snapshot.examIDs,
            defaultExamID: snapshot.defaultExam?.id,
            availablePackIDs: availablePackIDs ?? snapshot.packIDs(selectedExamID: examID),
            transform
        )
    }

    private func reloadWidgetIfNeeded() {
        guard usesSharedState else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
    }
}
