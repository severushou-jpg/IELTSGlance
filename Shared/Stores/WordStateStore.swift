import Foundation

final class WordStateStore: @unchecked Sendable {
    private let storage: SharedJSONFileStorage<WidgetDisplayState>
    private let picker: RandomWordPicker

    init(picker: RandomWordPicker = RandomWordPicker()) {
        let defaults = SharedConstants.stateDefaults()
        SharedConstants.migrateJSONFileToDefaultsIfNeeded(
            fileName: "display-state-v2.json",
            defaultsKey: SharedConstants.stateFileDefaultsKey,
            defaults: defaults
        )
        storage = SharedJSONFileStorage(
            fileName: "display-state-v2.json",
            defaultsKey: SharedConstants.stateFileDefaultsKey,
            defaults: defaults,
            lockURL: SharedConstants.defaultsStorageLockURL(),
            legacyDefaults: defaults,
            legacyKey: SharedConstants.stateDefaultsKey
        )
        self.picker = picker
    }

    init(defaults: UserDefaults, picker: RandomWordPicker = RandomWordPicker()) {
        storage = SharedJSONFileStorage(
            fileName: "display-state-v2.json",
            defaultsKey: SharedConstants.stateFileDefaultsKey,
            defaults: defaults,
            legacyDefaults: defaults,
            legacyKey: SharedConstants.stateDefaultsKey
        )
        self.picker = picker
    }

    func currentState(words: [IELTSWord]) -> WidgetDisplayState {
        storage.updateIfNeeded { decoded in
            let repaired = repair(decoded, words: words)
            return (repaired, decoded != repaired)
        }
    }

    @discardableResult
    func replaceWord(
        at position: Int,
        expectedWordID: String? = nil,
        expectedRevision: Int? = nil,
        displayedWordIDs: [String]? = nil,
        words: [IELTSWord]
    ) -> WidgetDisplayState {
        storage.updateIfNeeded { decoded in
            var state = repair(decoded, words: words)

            if let expectedRevision {
                if state.revision > expectedRevision {
                    return (state, decoded != state)
                }

                if let displayedWordIDs,
                   isValidDisplay(displayedWordIDs, words: words) {
                    state = WidgetDisplayState(
                        wordIDs: displayedWordIDs,
                        revision: expectedRevision,
                        updatedAt: decoded?.updatedAt ?? Date()
                    )
                }

                guard state.revision == expectedRevision else {
                    return (state, decoded != state)
                }
            }

            guard state.wordIDs.indices.contains(position) else {
                return (state, decoded != state)
            }
            if let expectedWordID, state.wordIDs[position] != expectedWordID {
                return (state, decoded != state)
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
                return (state, decoded != state)
            }

            state.wordIDs[position] = replacementID
            state.revision += 1
            state.updatedAt = Date()
            return (state, true)
        }
    }

    @discardableResult
    func shuffleAll(
        expectedRevision: Int? = nil,
        words: [IELTSWord]
    ) -> WidgetDisplayState {
        storage.updateIfNeeded { decoded in
            let current = repair(decoded, words: words)
            if let expectedRevision, current.revision != expectedRevision {
                return (current, decoded != current)
            }

            let count = min(SharedConstants.displayedWordCount, words.count)
            let ids = picker.pickUniqueIDs(count: count, from: words)
            return (WidgetDisplayState(
                wordIDs: ids,
                revision: current.revision + 1
            ), true)
        }
    }

    func words(for state: WidgetDisplayState, in allWords: [IELTSWord]) -> [IELTSWord] {
        let wordsByID = Dictionary(
            allWords.map { ($0.id, $0) },
            uniquingKeysWith: { existing, _ in existing }
        )
        return state.wordIDs.compactMap { wordsByID[$0] }
    }

    private func repair(_ state: WidgetDisplayState?, words: [IELTSWord]) -> WidgetDisplayState {
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

    private func isValidDisplay(_ wordIDs: [String], words: [IELTSWord]) -> Bool {
        guard wordIDs.count == min(SharedConstants.displayedWordCount, words.count),
              Set(wordIDs).count == wordIDs.count else {
            return false
        }
        let validIDs = Set(words.map(\.id))
        return wordIDs.allSatisfy(validIDs.contains)
    }
}
