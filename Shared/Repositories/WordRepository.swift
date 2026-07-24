import Foundation

struct WordRepositorySnapshot: Sendable {
    let catalog: VocabularyCatalog
    let issue: String?
    let isUsingFallback: Bool

    var exams: [VocabularyExam] { catalog.exams }

    var examIDs: [String] { exams.map(\.id) }

    var defaultExam: VocabularyExam? { catalog.defaultExam }

    var packs: [VocabularyPack] { defaultExam?.packs ?? [] }

    var words: [IELTSWord] { packs.flatMap(\.words) }

    var allWords: [IELTSWord] { exams.flatMap(\.packs).flatMap(\.words) }

    var packIDs: [String] { packs.map(\.id) }

    func exam(id: String?) -> VocabularyExam? {
        id.flatMap { selectedID in exams.first { $0.id == selectedID } } ?? defaultExam
    }

    func packs(selectedExamID: String?) -> [VocabularyPack] {
        exam(id: selectedExamID)?.packs ?? []
    }

    func packIDs(selectedExamID: String?) -> [String] {
        packs(selectedExamID: selectedExamID).map(\.id)
    }

    func words(selectedPackIDs: [String]) -> [IELTSWord] {
        words(selectedExamID: defaultExam?.id, selectedPackIDs: selectedPackIDs)
    }

    func words(selectedExamID: String?, selectedPackIDs: [String]) -> [IELTSWord] {
        let exam = exam(id: selectedExamID)
        guard let exam else { return [] }

        let selected = Set(selectedPackIDs)
        let candidates = exam.packs
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
        if let catalogSnapshot = loadCatalog(bundle: bundle) {
            return catalogSnapshot
        }

        return loadLegacyIELTSPacks(bundle: bundle)
    }

    private func loadCatalog(bundle: Bundle) -> WordRepositorySnapshot? {
        do {
            let data = try BundleResourceLoader.data(
                named: SharedConstants.catalogResourceName,
                extension: "json",
                in: bundle
            )
            let decodedCatalog = try JSONDecoder().decode(VocabularyCatalog.self, from: data)
            let normalizedCatalog = normalized(decodedCatalog)

            guard let normalizedCatalog, !normalizedCatalog.exams.isEmpty else {
                return fallbackSnapshot(issue: "本地考试词库为空，当前显示内置安全示例。")
            }

            return WordRepositorySnapshot(
                catalog: normalizedCatalog,
                issue: issue(for: normalizedCatalog),
                isUsingFallback: false
            )
        } catch BundleResourceLoader.ResourceError.notFound {
            return nil
        } catch {
            return fallbackSnapshot(issue: "考试词库加载失败：\(error.localizedDescription) 当前显示内置安全示例。")
        }
    }

    private func loadLegacyIELTSPacks(bundle: Bundle) -> WordRepositorySnapshot {
        do {
            let data = try BundleResourceLoader.data(
                named: SharedConstants.legacyIELTSPacksResourceName,
                extension: "json",
                in: bundle
            )
            let decodedPacks = try JSONDecoder().decode([VocabularyPack].self, from: data)
            let normalizedPacks = decodedPacks
                .sorted { $0.order < $1.order }
                .compactMap { normalized($0) }

            guard !normalizedPacks.isEmpty else {
                return fallbackSnapshot(issue: "本地词库为空，当前显示内置安全示例。")
            }

            let catalog = VocabularyCatalog.legacyIELTS(packs: normalizedPacks)
            return WordRepositorySnapshot(
                catalog: catalog,
                issue: issue(for: catalog),
                isUsingFallback: false
            )
        } catch {
            return fallbackSnapshot(issue: "词库加载失败：\(error.localizedDescription) 当前显示内置安全示例。")
        }
    }

    private func normalized(_ catalog: VocabularyCatalog) -> VocabularyCatalog? {
        let exams = catalog.exams
            .sorted { $0.order < $1.order }
            .compactMap { normalized($0) }

        guard !exams.isEmpty else { return nil }
        return VocabularyCatalog(
            schemaVersion: max(catalog.schemaVersion, 1),
            exams: exams
        )
    }

    private func normalized(_ exam: VocabularyExam) -> VocabularyExam? {
        let id = exam.id.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = exam.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !name.isEmpty else { return nil }

        let packs = exam.packs
            .sorted { $0.order < $1.order }
            .compactMap { normalized($0) }
        guard !packs.isEmpty else { return nil }

        return VocabularyExam(
            id: id,
            name: name,
            subtitle: exam.subtitle,
            systemImage: exam.systemImage,
            order: exam.order,
            packs: packs
        )
    }

    private func normalized(_ pack: VocabularyPack) -> VocabularyPack? {
        guard !pack.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !pack.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        var seenIDs = Set<String>()
        var seenWords = Set<String>()

        let words: [IELTSWord] = pack.words.compactMap { item -> IELTSWord? in
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
            systemImage: pack.systemImage,
            order: pack.order,
            words: words
        )
    }

    private func issue(for catalog: VocabularyCatalog) -> String? {
        let wordCount = catalog.defaultExam?.wordCount ?? 0
        return wordCount < SharedConstants.displayedWordCount
            ? "词库少于五个有效词条，当前只能显示可用内容。"
            : nil
    }

    private func fallbackSnapshot(issue: String) -> WordRepositorySnapshot {
        WordRepositorySnapshot(catalog: .fallback, issue: issue, isUsingFallback: true)
    }
}
