import Foundation

final class WordStateStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let picker: RandomWordPicker
    private let lock = NSLock()

    init(defaults: UserDefaults = SharedConstants.stateDefaults(), picker: RandomWordPicker = RandomWordPicker()) {
        self.defaults = defaults
        self.picker = picker
    }

    func currentState(words: [GREWord]) -> WidgetDisplayState {
        lock.lock()
        defer { lock.unlock() }

        let decoded = decodeState()
        let repaired = repair(decoded, words: words)
        if decoded != repaired {
            saveUnlocked(repaired)
        }
        return repaired
    }

    @discardableResult
    func replaceWord(at position: Int, expectedWordID: String? = nil, words: [GREWord]) -> WidgetDisplayState {
        lock.lock()
        defer { lock.unlock() }

        var state = repair(decodeState(), words: words)
        guard state.wordIDs.indices.contains(position) else { return state }
        if let expectedWordID, state.wordIDs[position] != expectedWordID {
            return state
        }

        let replacedID = state.wordIDs[position]
        let otherIDs = Set(state.wordIDs.enumerated().compactMap { index, id in
            index == position ? nil : id
        })

        guard let replacementID = picker.replacementID(
            from: words,
            excluding: otherIDs,
            avoiding: replacedID
        ) else {
            return state
        }

        state.wordIDs[position] = replacementID
        state.revision += 1
        state.updatedAt = Date()
        saveUnlocked(state)
        return state
    }

    @discardableResult
    func shuffleAll(words: [GREWord]) -> WidgetDisplayState {
        lock.lock()
        defer { lock.unlock() }

        let count = min(SharedConstants.displayedWordCount, words.count)
        let ids = picker.pickUniqueIDs(count: count, from: words)
        let previousRevision = decodeState()?.revision ?? 0
        let state = WidgetDisplayState(wordIDs: ids, revision: previousRevision + 1)
        saveUnlocked(state)
        return state
    }

    func words(for state: WidgetDisplayState, in allWords: [GREWord]) -> [GREWord] {
        let wordsByID = Dictionary(uniqueKeysWithValues: allWords.map { ($0.id, $0) })
        return state.wordIDs.compactMap { wordsByID[$0] }
    }

    private func decodeState() -> WidgetDisplayState? {
        guard let data = defaults.data(forKey: SharedConstants.stateDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(WidgetDisplayState.self, from: data)
    }

    private func repair(_ state: WidgetDisplayState?, words: [GREWord]) -> WidgetDisplayState {
        let validIDs = Set(words.map(\.id))
        var seen = Set<String>()
        var repairedIDs = (state?.wordIDs ?? []).filter { id in
            validIDs.contains(id) && seen.insert(id).inserted
        }
        repairedIDs = Array(repairedIDs.prefix(SharedConstants.displayedWordCount))

        let missingCount = min(SharedConstants.displayedWordCount, words.count) - repairedIDs.count
        if missingCount > 0 {
            repairedIDs.append(contentsOf: picker.pickUniqueIDs(
                count: missingCount,
                from: words,
                excluding: Set(repairedIDs)
            ))
        }

        return WidgetDisplayState(
            wordIDs: repairedIDs,
            revision: state?.revision ?? 0,
            updatedAt: state?.updatedAt ?? Date()
        )
    }

    private func saveUnlocked(_ state: WidgetDisplayState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: SharedConstants.stateDefaultsKey)
    }
}
