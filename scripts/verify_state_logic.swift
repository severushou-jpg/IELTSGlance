import Foundation

@main
enum VerifyStateLogic {
    static func main() throws {
        let suiteName = "IELTSGlance.StateLogicVerification.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw VerificationError("Could not create isolated UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let words = (0..<12).map { index in
            IELTSWord(
                id: "word-\(index)",
                word: "word\(index)",
                partOfSpeech: "n.",
                chineseMeaning: "测试词\(index)",
                synonyms: ["sample", "example"],
                exampleSentence: "This is sample word \(index).",
                source: "Verification fixture"
            )
        }
        let store = WordStateStore(defaults: defaults)

        let first = store.currentState(words: words)
        try require(first.wordIDs.count == 5, "first load must select five words")
        try require(Set(first.wordIDs).count == 5, "first load must contain unique words")

        let stable = store.currentState(words: words)
        try require(stable.wordIDs == first.wordIDs, "ordinary reload must preserve the current five words")

        let replaced = store.replaceWord(at: 2, expectedWordID: first.wordIDs[2], words: words)
        try require(replaced.wordIDs[2] != first.wordIDs[2], "replacement should avoid the word just removed")
        try require(Set(replaced.wordIDs).count == 5, "replacement must preserve uniqueness")
        for index in replaced.wordIDs.indices where index != 2 {
            try require(replaced.wordIDs[index] == first.wordIDs[index], "single replacement changed another position")
        }

        let staleTap = store.replaceWord(at: 2, expectedWordID: first.wordIDs[2], words: words)
        try require(staleTap.wordIDs == replaced.wordIDs, "a stale rapid tap must not replace the newer word")

        let widgetReplacement = store.replaceWord(
            at: 1,
            expectedWordID: replaced.wordIDs[1],
            expectedRevision: replaced.revision,
            displayedWordIDs: replaced.wordIDs,
            words: words
        )
        let duplicateWidgetTap = store.replaceWord(
            at: 1,
            expectedWordID: replaced.wordIDs[1],
            expectedRevision: replaced.revision,
            displayedWordIDs: replaced.wordIDs,
            words: words
        )
        try require(
            duplicateWidgetTap == widgetReplacement,
            "a repeated Widget interaction must be idempotent"
        )

        let shuffled = store.shuffleAll(
            expectedRevision: widgetReplacement.revision,
            words: words
        )
        try require(shuffled.wordIDs.count == 5, "shuffle must select five words")
        try require(Set(shuffled.wordIDs).count == 5, "shuffle must contain unique words")

        let duplicateShuffle = store.shuffleAll(
            expectedRevision: widgetReplacement.revision,
            words: words
        )
        try require(
            duplicateShuffle == shuffled,
            "a repeated Shuffle interaction must not shuffle again"
        )

        defaults.set(Data("damaged".utf8), forKey: SharedConstants.stateFileDefaultsKey)
        let repaired = store.currentState(words: words)
        try require(repaired.wordIDs.count == 5, "damaged defaults must recover safely")
        try require(Set(repaired.wordIDs).count == 5, "recovered state must contain unique words")

        print("State logic verification passed")
    }

    private static func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw VerificationError(message) }
    }

    struct VerificationError: LocalizedError {
        let message: String
        init(_ message: String) { self.message = message }
        var errorDescription: String? { message }
    }
}
