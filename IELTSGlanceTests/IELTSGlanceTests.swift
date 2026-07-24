import XCTest
@testable import IELTSGlance

final class IELTSGlanceTests: XCTestCase {
    func testBundledVocabularyHasFifteenUniquePacksOfOneHundred() throws {
        let snapshot = WordRepository().load()
        XCTAssertFalse(snapshot.isUsingFallback, snapshot.issue ?? "Unexpected fallback")
        XCTAssertEqual(snapshot.exams.count, 4)
        XCTAssertEqual(snapshot.examIDs, [SharedConstants.legacyIELTSExamID, "cet4", "cet6", "gre"])
        XCTAssertEqual(snapshot.defaultExam?.id, SharedConstants.legacyIELTSExamID)
        XCTAssertEqual(snapshot.defaultExam?.name, "雅思")
        XCTAssertEqual(snapshot.packs.count, 15)
        XCTAssertTrue(snapshot.packs.allSatisfy { $0.words.count == 100 })
        XCTAssertEqual(snapshot.words.count, 1500)
        XCTAssertEqual(Set(snapshot.words.map(\.id)).count, 1500)
        XCTAssertEqual(Set(snapshot.words.map { $0.word.lowercased() }).count, 1500)
        XCTAssertEqual(
            snapshot.packs.map(\.id),
            (1...15).map { String(format: "ielts-pack-%02d", $0) }
        )
        XCTAssertEqual(snapshot.packs.map(\.name), [
            "写作论证与证据",
            "图表趋势与比较",
            "因果变化与解决方案",
            "描述评价与程度",
            "沟通语言与媒体",
            "教育研究与学习",
            "工作商业与经济",
            "社会政府与公共服务",
            "环境自然与能源",
            "科学技术与工程",
            "健康身心与医疗",
            "人物性格与关系",
            "法律犯罪与冲突",
            "城市住房与交通",
            "生活文化与消费"
        ])
        XCTAssertTrue(snapshot.packs.allSatisfy { !$0.subtitle.isEmpty })
        XCTAssertTrue(snapshot.packs.allSatisfy { !($0.systemImage ?? "").isEmpty })
        XCTAssertTrue(snapshot.words.allSatisfy { $0.id.hasPrefix("ielts-") })
        XCTAssertTrue(snapshot.words.allSatisfy {
            $0.source?.contains("IELTS Glance normalized") == true
        })
    }

    func testBundledCETVocabularyHasFifteenFrequencyPacksOfOneHundred() throws {
        let snapshot = WordRepository().load()

        assertCETExam(snapshot, examID: "cet4", namePrefix: "四级", sourceLabel: "CET4")
        assertCETExam(snapshot, examID: "cet6", namePrefix: "六级", sourceLabel: "CET6")
    }

    func testBundledGREVocabularyHasThirtyTopicPacksOfOneHundred() throws {
        let snapshot = WordRepository().load()

        assertGREExam(snapshot)
    }

    func testSelectedPacksDefineTheRandomPool() {
        let snapshot = WordRepository().load()
        let selected = Array(snapshot.packs.prefix(2).map(\.id))
        let words = snapshot.words(selectedPackIDs: selected)
        XCTAssertEqual(words.count, 200)
        XCTAssertEqual(Set(words.map(\.id)).count, 200)
    }

    func testLegacyIELTSPacksAreExposedThroughGenericCatalog() {
        let snapshot = WordRepository().load()

        let legacyCatalog = VocabularyCatalog.legacyIELTS(packs: snapshot.packs)

        XCTAssertEqual(legacyCatalog.schemaVersion, 1)
        XCTAssertEqual(legacyCatalog.exams.map(\.id), [SharedConstants.legacyIELTSExamID])
        XCTAssertEqual(legacyCatalog.defaultExam?.wordCount, 1500)
        XCTAssertEqual(
            snapshot.words(
                selectedExamID: SharedConstants.legacyIELTSExamID,
                selectedPackIDs: Array(snapshot.packIDs.prefix(1))
            ).count,
            100
        )
    }

    func testPreferencesAlwaysKeepAtLeastOneAvailablePack() {
        let repaired = IELTSGlancePreferences(
            selectedPackIDs: ["missing"],
            defaultTextSize: .followApp,
            synonymLimit: 99
        ).repaired(
            availableExamIDs: ["ielts", "cet4"],
            defaultExamID: "ielts",
            availablePackIDs: ["pack-1", "pack-2"]
        )
        XCTAssertEqual(repaired.selectedExamID, "ielts")
        XCTAssertEqual(repaired.selectedPackIDs, ["pack-1"])
        XCTAssertEqual(repaired.defaultTextSize, .comfortable)
        XCTAssertEqual(repaired.synonymLimit, 3)
        XCTAssertEqual(repaired.schemaVersion, 4)
    }

    func testLegacyExtraLargeDefaultMigratesToComfortable() {
        let repaired = IELTSGlancePreferences(
            schemaVersion: nil,
            selectedPackIDs: ["pack-1"],
            defaultTextSize: .legacyExtraLarge,
            synonymLimit: 3
        ).repaired(
            availableExamIDs: ["ielts"],
            defaultExamID: "ielts",
            availablePackIDs: ["pack-1"]
        )
        XCTAssertEqual(repaired.defaultTextSize, .comfortable)
        XCTAssertEqual(repaired.schemaVersion, 4)
    }

    func testNewExtraLargePreferenceRemainsAvailable() {
        let repaired = IELTSGlancePreferences(
            schemaVersion: 4,
            selectedExamID: "cet4",
            selectedPackIDs: ["pack-1"],
            defaultTextSize: .extraLarge,
            synonymLimit: 3
        ).repaired(
            availableExamIDs: ["ielts", "cet4"],
            defaultExamID: "ielts",
            availablePackIDs: ["pack-1"]
        )
        XCTAssertEqual(repaired.selectedExamID, "cet4")
        XCTAssertEqual(repaired.defaultTextSize, .extraLarge)
        XCTAssertEqual(repaired.schemaVersion, 4)
    }

    func testLegacyWidgetExtraLargeRawValueMigratesWithoutAffectingNewChoice() throws {
        let legacy = try JSONDecoder().decode(
            WidgetTextSize.self,
            from: Data("\"extraLarge\"".utf8)
        )
        XCTAssertEqual(legacy, .legacyExtraLarge)
        XCTAssertEqual(legacy.resolved(defaultSize: .comfortable), .comfortable)

        let encodedNewChoice = try JSONEncoder().encode(WidgetTextSize.extraLarge)
        XCTAssertEqual(String(decoding: encodedNewChoice, as: UTF8.self), "\"extraLargeV2\"")
    }

    func testSingleReplacementPreservesOtherFourPositions() throws {
        let (store, defaults) = try makeStore()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let words = Array(WordRepository().load().words.prefix(25))
        let before = store.currentState(words: words)
        XCTAssertEqual(before.wordIDs.count, 5)
        let after = store.replaceWord(at: 2, expectedWordID: before.wordIDs[2], words: words)
        XCTAssertEqual(Array(before.wordIDs.prefix(2)), Array(after.wordIDs.prefix(2)))
        XCTAssertEqual(Array(before.wordIDs.suffix(2)), Array(after.wordIDs.suffix(2)))
        XCTAssertNotEqual(before.wordIDs[2], after.wordIDs[2])
        XCTAssertEqual(Set(after.wordIDs).count, 5)
    }

    func testWidgetReplacementUsesVisibleSnapshotAndIsIdempotent() throws {
        let (store, defaults) = try makeStore()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let words = Array(WordRepository().load().words.prefix(25))
        let visibleIDs = Array(words.prefix(5).map(\.id))

        defaults.set(Data("damaged".utf8), forKey: SharedConstants.stateFileDefaultsKey)
        let firstResult = store.replaceWord(
            at: 2,
            expectedWordID: visibleIDs[2],
            expectedRevision: 41,
            displayedWordIDs: visibleIDs,
            words: words
        )

        XCTAssertEqual(firstResult.revision, 42)
        XCTAssertNotEqual(firstResult.wordIDs[2], visibleIDs[2])
        for index in visibleIDs.indices where index != 2 {
            XCTAssertEqual(firstResult.wordIDs[index], visibleIDs[index])
        }

        let duplicateResult = store.replaceWord(
            at: 2,
            expectedWordID: visibleIDs[2],
            expectedRevision: 41,
            displayedWordIDs: visibleIDs,
            words: words
        )
        XCTAssertEqual(duplicateResult.wordIDs, firstResult.wordIDs)
        XCTAssertEqual(duplicateResult.revision, firstResult.revision)
        XCTAssertEqual(duplicateResult.updatedAt, firstResult.updatedAt)
    }

    func testWidgetShuffleIgnoresRepeatedStaleInteraction() throws {
        let (store, defaults) = try makeStore()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let words = Array(WordRepository().load().words.prefix(100))
        let before = store.currentState(words: words)

        let firstResult = store.shuffleAll(
            expectedRevision: before.revision,
            words: words
        )
        let duplicateResult = store.shuffleAll(
            expectedRevision: before.revision,
            words: words
        )

        XCTAssertEqual(firstResult.revision, before.revision + 1)
        XCTAssertEqual(duplicateResult.wordIDs, firstResult.wordIDs)
        XCTAssertEqual(duplicateResult.revision, firstResult.revision)
        XCTAssertEqual(duplicateResult.updatedAt, firstResult.updatedAt)
    }

    func testOrdinaryReloadDoesNotRewriteValidState() throws {
        let (store, defaults) = try makeStore()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let words = Array(WordRepository().load().words.prefix(25))
        _ = store.currentState(words: words)
        let storedBefore = defaults.data(forKey: SharedConstants.stateFileDefaultsKey)

        _ = store.currentState(words: words)

        XCTAssertEqual(defaults.data(forKey: SharedConstants.stateFileDefaultsKey), storedBefore)
    }

    func testCorruptStateRepairsWithoutCrashing() throws {
        let (store, defaults) = try makeStore()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        defaults.set(Data("not-json".utf8), forKey: SharedConstants.stateFileDefaultsKey)
        let words = Array(WordRepository().load().words.prefix(10))
        let repaired = store.currentState(words: words)
        XCTAssertEqual(repaired.wordIDs.count, 5)
        XCTAssertEqual(Set(repaired.wordIDs).count, 5)
    }

    func testShuffleProducesFiveUniqueWords() throws {
        let (store, defaults) = try makeStore()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let state = store.shuffleAll(words: Array(WordRepository().load().words.prefix(100)))
        XCTAssertEqual(state.wordIDs.count, 5)
        XCTAssertEqual(Set(state.wordIDs).count, 5)
    }

    func testLearningProgressRecordsSeenCount() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let store = VocabularyLearningProgressStore(defaults: defaults)

        _ = store.recordSeen(wordID: "ielts-test")
        let second = store.recordSeen(wordID: "ielts-test")

        XCTAssertEqual(second.wordID, "ielts-test")
        XCTAssertEqual(second.status, .seen)
        XCTAssertEqual(second.seenCount, 2)
        XCTAssertEqual(store.record(for: "ielts-test")?.seenCount, 2)
    }

    func testLearningProgressDoesNotDowngradeMasteredWhenSeenAgain() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let store = VocabularyLearningProgressStore(defaults: defaults)

        _ = store.setStatus(.mastered, wordID: "ielts-test")
        let seenAgain = store.recordSeen(wordID: "ielts-test")

        XCTAssertEqual(seenAgain.status, .mastered)
        XCTAssertEqual(seenAgain.seenCount, 1)
    }

    func testLearningProgressCanClearReviewLaterStatus() throws {
        let defaults = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let store = VocabularyLearningProgressStore(defaults: defaults)

        _ = store.recordSeen(wordID: "ielts-test")
        _ = store.setStatus(.reviewLater, wordID: "ielts-test")
        let cleared = store.clearStatus(.reviewLater, wordID: "ielts-test")

        XCTAssertEqual(cleared?.status, .seen)
        XCTAssertEqual(cleared?.seenCount, 1)
        XCTAssertEqual(store.record(for: "ielts-test")?.status, .seen)
    }

    func testSprintPackStateDoesNotRepeatWithinRound() {
        let ids = (1...12).map { "word-\($0)" }
        var state = SprintPackState(packID: "pack", wordIDs: ids, targetRounds: 2)
        var seen = Set<String>()

        while state.completedRounds == 0 {
            let batch = state.visibleWordIDs(count: 5)
            XCTAssertEqual(Set(batch).count, batch.count)
            batch.forEach { XCTAssertTrue(seen.insert($0).inserted) }
            state.advance(count: batch.count, allWordIDs: ids)
        }

        XCTAssertEqual(seen.count, ids.count)
        XCTAssertEqual(state.completedRounds, 1)
    }

    func testSprintPackStateAllowsReviewLaterOnlyOnFinalRound() {
        let ids = (1...6).map { "word-\($0)" }
        var state = SprintPackState(packID: "pack", wordIDs: ids, targetRounds: 2)

        state.markReviewLater(wordID: ids[0])
        XCTAssertTrue(state.reviewLaterWordIDs.isEmpty)

        state.advance(count: ids.count, allWordIDs: ids)
        XCTAssertTrue(state.isFinalRound)
        state.markReviewLater(wordID: ids[0])
        state.markReviewLater(wordID: ids[0])

        XCTAssertEqual(state.reviewLaterWordIDs, [ids[0]])

        state.unmarkReviewLater(wordID: ids[0])
        XCTAssertTrue(state.reviewLaterWordIDs.isEmpty)
    }

    func testDuplicateIDsInFutureDataDoNotCrashStateMapping() throws {
        let (store, defaults) = try makeStore()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let baseWords = Array(WordRepository().load().words.prefix(5))
        let duplicatedWords = baseWords + [baseWords[0]]
        let state = WidgetDisplayState(wordIDs: baseWords.map(\.id))

        let resolved = store.words(for: state, in: duplicatedWords)

        XCTAssertEqual(resolved.map(\.id), baseWords.map(\.id))
    }

    private func assertCETExam(
        _ snapshot: WordRepositorySnapshot,
        examID: String,
        namePrefix: String,
        sourceLabel: String
    ) {
        let packs = snapshot.packs(selectedExamID: examID)
        let words = snapshot.words(
            selectedExamID: examID,
            selectedPackIDs: packs.map(\.id)
        )

        XCTAssertEqual(packs.count, 15)
        XCTAssertEqual(packs.map { $0.words.count }, Array(repeating: 100, count: 15))
        XCTAssertEqual(packs.prefix(5).map(\.name), (1...5).map { String(format: "\(namePrefix)高频 %02d", $0) })
        XCTAssertEqual(packs.dropFirst(5).prefix(5).map(\.name), (1...5).map { String(format: "\(namePrefix)中频 %02d", $0) })
        XCTAssertEqual(packs.dropFirst(10).prefix(5).map(\.name), (1...5).map { String(format: "\(namePrefix)低频 %02d", $0) })
        XCTAssertEqual(words.count, 1500)
        XCTAssertEqual(Set(words.map(\.id)).count, 1500)
        XCTAssertEqual(Set(words.map { $0.word.lowercased() }).count, 1500)
        XCTAssertTrue(words.allSatisfy { $0.id.hasPrefix("\(examID)-") })
        XCTAssertTrue(words.allSatisfy {
            $0.source?.contains("KyleBing/english-vocabulary \(sourceLabel) JSON") == true
        })
    }

    private func assertGREExam(_ snapshot: WordRepositorySnapshot) {
        let expectedNames = [
            "性格与人格特质",
            "情绪与心理状态",
            "态度、立场与评价",
            "争论、批判与反驳",
            "赞同、支持与证明",
            "欺骗、伪装与虚假",
            "清晰、模糊与复杂",
            "变化、发展与衰退",
            "权力、统治与服从",
            "社会制度与群体",
            "道德、正义与责任",
            "艺术、审美与风格",
            "文学、语言与表达",
            "科学研究与方法",
            "逻辑、推理与因果",
            "数量、程度与范围",
            "时间、持续与短暂",
            "空间、位置与移动",
            "稀有、平凡与典型",
            "重要、琐碎与无关",
            "困难、障碍与解决",
            "冲突、战争与破坏",
            "和解、秩序与稳定",
            "财富、贫困与资源",
            "工作、效率与能力",
            "教育、知识与学习",
            "自然、环境与生物",
            "宗教、传统与仪式",
            "身体、疾病与医学",
            "综合抽象高频词"
        ]
        let packs = snapshot.packs(selectedExamID: "gre")
        let words = snapshot.words(
            selectedExamID: "gre",
            selectedPackIDs: packs.map(\.id)
        )

        XCTAssertEqual(packs.count, 30)
        XCTAssertEqual(packs.map(\.name), expectedNames)
        XCTAssertEqual(packs.map { $0.words.count }, Array(repeating: 100, count: 30))
        XCTAssertTrue(packs.allSatisfy { !$0.name.hasPrefix("GRE") })
        XCTAssertTrue(packs.allSatisfy { !($0.systemImage ?? "").isEmpty })
        XCTAssertEqual(words.count, 3000)
        XCTAssertEqual(Set(words.map(\.id)).count, 3000)
        XCTAssertEqual(Set(words.map { $0.word.lowercased() }).count, 3000)
        XCTAssertTrue(words.allSatisfy { $0.id.hasPrefix("gre-") })
        XCTAssertTrue(words.allSatisfy {
            $0.source?.contains("ECDICT gre-tagged headword") == true
        })
    }

    private func makeStore() throws -> (WordStateStore, UserDefaults) {
        let defaults = try makeDefaults()
        return (WordStateStore(defaults: defaults), defaults)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suite = "IELTSGlanceTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            throw XCTSkip("Unable to create isolated UserDefaults suite")
        }
        defaults.set(suite, forKey: "IELTSGlanceTestsSuiteName")
        return defaults
    }

    private func defaultsSuiteName(_ defaults: UserDefaults) -> String {
        defaults.string(forKey: "IELTSGlanceTestsSuiteName") ?? "IELTSGlanceTests"
    }
}
