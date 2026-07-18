import Foundation

struct WordRepositorySnapshot: Sendable {
    let packs: [VocabularyPack]
    let issue: String?
    let isUsingFallback: Bool

    var words: [GREWord] { packs.flatMap(\.words) }

    var packIDs: [String] { packs.map(\.id) }

    func words(selectedPackIDs: [String]) -> [GREWord] {
        let selected = Set(selectedPackIDs)
        let candidates = packs
            .filter { selected.contains($0.id) }
            .flatMap(\.words)

        var seenIDs = Set<String>()
        var seenWords = Set<String>()
        return candidates.filter { word in
            seenIDs.insert(word.id).inserted && seenWords.insert(word.word.lowercased()).inserted
        }
    }
}

struct WordRepository: Sendable {
    func load(bundle: Bundle = .main) -> WordRepositorySnapshot {
        do {
            let data = try BundleResourceLoader.data(named: "gre_word_packs", extension: "json", in: bundle)
            let decodedPacks = try JSONDecoder().decode([VocabularyPack].self, from: data)
            let normalizedPacks = decodedPacks
                .sorted { $0.order < $1.order }
                .compactMap { normalized($0) }

            guard !normalizedPacks.isEmpty else {
                return fallbackSnapshot(issue: "本地词库为空，当前显示内置安全示例。")
            }

            let wordCount = normalizedPacks.reduce(0) { $0 + $1.words.count }
            let issue = wordCount < SharedConstants.displayedWordCount
                ? "词库少于五个有效词条，当前只能显示可用内容。"
                : nil
            return WordRepositorySnapshot(packs: normalizedPacks, issue: issue, isUsingFallback: false)
        } catch {
            return fallbackSnapshot(issue: "词库加载失败：\(error.localizedDescription) 当前显示内置安全示例。")
        }
    }

    private func normalized(_ pack: VocabularyPack) -> VocabularyPack? {
        guard !pack.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !pack.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        var seenIDs = Set<String>()
        var seenWords = Set<String>()

        let words: [GREWord] = pack.words.compactMap { item -> GREWord? in
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

        guard !words.isEmpty else { return nil }
        return VocabularyPack(
            id: pack.id,
            name: pack.name,
            subtitle: pack.subtitle,
            order: pack.order,
            words: words
        )
    }

    private func fallbackSnapshot(issue: String) -> WordRepositorySnapshot {
        WordRepositorySnapshot(packs: [.fallback], issue: issue, isUsingFallback: true)
    }
}
