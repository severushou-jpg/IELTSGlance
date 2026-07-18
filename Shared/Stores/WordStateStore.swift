import Foundation

final class WordStateStore: @unchecked Sendable {
    private let storage: SharedJSONFileStorage<WidgetDisplayState>
    private let picker: RandomWordPicker

    init(picker: RandomWordPicker = RandomWordPicker()) {
        storage = SharedJSONFileStorage(
            fileName: "display-state-v2.json",
            defaultsKey: SharedConstants.stateFileDefaultsKey,
            legacyDefaults: SharedConstants.stateDefaults(),
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

    func currentState(words: [GREWord]) -> WidgetDisplayState {
        storage.update { decoded in
            repair(decoded, words: words)
        }
    }

    @discardableResult
    func replaceWord(at position: Int, expectedWordID: String? = nil, words: [GREWord]) -> WidgetDisplayState {
        storage.update { decoded in
            var state = repair(decoded, words: words)
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
            return state
        }
    }

    @discardableResult
    func shuffleAll(words: [GREWord]) -> WidgetDisplayState {
        storage.update { decoded in
            let count = min(SharedConstants.displayedWordCount, words.count)
            let ids = picker.pickUniqueIDs(count: count, from: words)
            return WidgetDisplayState(
                wordIDs: ids,
                revision: (decoded?.revision ?? 0) + 1
            )
        }
    }

    func words(for state: WidgetDisplayState, in allWords: [GREWord]) -> [GREWord] {
        let wordsByID = Dictionary(uniqueKeysWithValues: allWords.map { ($0.id, $0) })
        return state.wordIDs.compactMap { wordsByID[$0] }
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
}
