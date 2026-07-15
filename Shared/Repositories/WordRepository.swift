import Foundation

struct WordRepositorySnapshot: Sendable {
    let words: [GREWord]
    let issue: String?
    let isUsingFallback: Bool
}

struct WordRepository: Sendable {
    func load(bundle: Bundle = .main) -> WordRepositorySnapshot {
        do {
            let data = try BundleResourceLoader.data(named: "gre_words", extension: "json", in: bundle)
            let decodedWords = try JSONDecoder().decode([GREWord].self, from: data)
            let normalizedWords = normalized(decodedWords)

            guard !normalizedWords.isEmpty else {
                return fallbackSnapshot(issue: "本地词库为空，当前显示内置安全示例。")
            }

            let issue = normalizedWords.count < SharedConstants.displayedWordCount
                ? "词库少于五个有效词条，当前只能显示可用内容。"
                : nil
            return WordRepositorySnapshot(words: normalizedWords, issue: issue, isUsingFallback: false)
        } catch {
            return fallbackSnapshot(issue: "词库加载失败：\(error.localizedDescription) 当前显示内置安全示例。")
        }
    }

    private func normalized(_ words: [GREWord]) -> [GREWord] {
        var seenIDs = Set<String>()
        var seenWords = Set<String>()

        return words.compactMap { item in
            let id = item.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let word = item.word.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedWord = word.lowercased()
            guard !id.isEmpty,
                  !word.isEmpty,
                  !item.partOfSpeech.isEmpty,
                  !item.chineseMeaning.isEmpty,
                  !item.synonyms.isEmpty,
                  !item.exampleSentence.isEmpty,
                  seenIDs.insert(id).inserted,
                  seenWords.insert(normalizedWord).inserted else {
                return nil
            }
            return item
        }
    }

    private func fallbackSnapshot(issue: String) -> WordRepositorySnapshot {
        WordRepositorySnapshot(words: GREWord.fallbackWords, issue: issue, isUsingFallback: true)
    }
}
