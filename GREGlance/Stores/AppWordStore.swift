import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
final class AppWordStore {
    private let stateStore: WordStateStore
    private let snapshot: WordRepositorySnapshot

    private(set) var displayedWords: [GREWord] = []
    private(set) var issue: String?

    init() {
        let repository = WordRepository()
        snapshot = repository.load()
        stateStore = WordStateStore()
        issue = snapshot.issue
        reloadFromPersistence()
        reloadWidgetIfNeeded()
    }

    var totalWordCount: Int { snapshot.words.count }
    var usesFallbackData: Bool { snapshot.isUsingFallback }
    var usesSharedState: Bool { SharedConstants.usesAppGroup }
    var stateModeDescription: String { SharedConstants.stateModeDescription }

    func reloadFromPersistence() {
        let state = stateStore.currentState(words: snapshot.words)
        displayedWords = stateStore.words(for: state, in: snapshot.words)
    }

    func replaceWord(at position: Int) {
        guard displayedWords.indices.contains(position) else { return }
        let state = stateStore.replaceWord(
            at: position,
            expectedWordID: displayedWords[position].id,
            words: snapshot.words
        )
        displayedWords = stateStore.words(for: state, in: snapshot.words)
        reloadWidgetIfNeeded()
    }

    func shuffleAll() {
        let state = stateStore.shuffleAll(words: snapshot.words)
        displayedWords = stateStore.words(for: state, in: snapshot.words)
        reloadWidgetIfNeeded()
    }

    private func reloadWidgetIfNeeded() {
        guard usesSharedState else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
    }
}
