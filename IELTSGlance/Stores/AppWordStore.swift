import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
final class AppWordStore {
    private let stateStore: WordStateStore
    private let preferencesStore: SharedPreferencesStore
    private let snapshot: WordRepositorySnapshot

    private(set) var displayedWords: [IELTSWord] = []
    private(set) var issue: String?
    private(set) var preferences: IELTSGlancePreferences

    init() {
        let repository = WordRepository()
        snapshot = repository.load()
        stateStore = WordStateStore()
        preferencesStore = SharedPreferencesStore()
        preferences = preferencesStore.load(availablePackIDs: snapshot.packIDs)
        issue = snapshot.issue
        reloadFromPersistence()
    }

    var totalWordCount: Int { snapshot.words.count }
    var packs: [VocabularyPack] { snapshot.packs }
    var selectedPackIDs: Set<String> { Set(preferences.selectedPackIDs) }
    var selectedWordCount: Int { selectedWords.count }
    var defaultTextSize: WidgetTextSize { preferences.defaultTextSize }
    var synonymLimit: Int { preferences.synonymLimit }
    var usesFallbackData: Bool { snapshot.isUsingFallback }
    var usesSharedState: Bool { SharedConstants.usesAppGroup }
    var stateModeDescription: String { SharedConstants.stateModeDescription }

    func reloadFromPersistence() {
        preferences = preferencesStore.load(availablePackIDs: snapshot.packIDs)
        let words = selectedWords
        let state = stateStore.currentState(words: words)
        displayedWords = stateStore.words(for: state, in: words)
    }

    func replaceWord(at position: Int) {
        guard displayedWords.indices.contains(position) else { return }
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
        updatePreferences { $0.selectedPackIDs = snapshot.packIDs.filter(selected.contains) }
        shuffleAll()
    }

    func selectAllPacks() {
        updatePreferences { $0.selectedPackIDs = snapshot.packIDs }
        shuffleAll()
    }

    func selectOnlyPack(_ packID: String) {
        guard snapshot.packIDs.contains(packID) else { return }
        updatePreferences { $0.selectedPackIDs = [packID] }
        shuffleAll()
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

    private var selectedWords: [IELTSWord] {
        snapshot.words(selectedPackIDs: preferences.selectedPackIDs)
    }

    private func updatePreferences(_ transform: (inout IELTSGlancePreferences) -> Void) {
        preferences = preferencesStore.update(availablePackIDs: snapshot.packIDs, transform)
    }

    private func reloadWidgetIfNeeded() {
        guard usesSharedState else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
    }
}
