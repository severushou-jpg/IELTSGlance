import XCTest
@testable import IELTSGlance

final class IELTSGlanceTests: XCTestCase {
    func testBundledVocabularyHasFifteenUniquePacksOfOneHundred() throws {
        let snapshot = WordRepository().load()
        XCTAssertFalse(snapshot.isUsingFallback, snapshot.issue ?? "Unexpected fallback")
        XCTAssertEqual(snapshot.packs.count, 15)
        XCTAssertTrue(snapshot.packs.allSatisfy { $0.words.count == 100 })
        XCTAssertEqual(snapshot.words.count, 1500)
        XCTAssertEqual(Set(snapshot.words.map(\.id)).count, 1500)
        XCTAssertEqual(Set(snapshot.words.map { $0.word.lowercased() }).count, 1500)
        XCTAssertEqual(
            snapshot.packs.map(\.id),
            (1...15).map { String(format: "ielts-pack-%02d", $0) }
        )
        XCTAssertTrue(snapshot.words.allSatisfy { $0.id.hasPrefix("ielts-") })
        XCTAssertTrue(snapshot.words.allSatisfy {
            $0.source?.contains("IELTS Glance normalized") == true
        })
    }

    func testSelectedPacksDefineTheRandomPool() {
        let snapshot = WordRepository().load()
        let selected = Array(snapshot.packs.prefix(2).map(\.id))
        let words = snapshot.words(selectedPackIDs: selected)
        XCTAssertEqual(words.count, 200)
        XCTAssertEqual(Set(words.map(\.id)).count, 200)
    }

    func testPreferencesAlwaysKeepAtLeastOneAvailablePack() {
        let repaired = IELTSGlancePreferences(
            selectedPackIDs: ["missing"],
            defaultTextSize: .followApp,
            synonymLimit: 99
        ).repaired(availablePackIDs: ["pack-1", "pack-2"])
        XCTAssertEqual(repaired.selectedPackIDs, ["pack-1"])
        XCTAssertEqual(repaired.defaultTextSize, .comfortable)
        XCTAssertEqual(repaired.synonymLimit, 3)
        XCTAssertEqual(repaired.schemaVersion, 3)
    }

    func testLegacyExtraLargeDefaultMigratesToComfortable() {
        let repaired = IELTSGlancePreferences(
            schemaVersion: nil,
            selectedPackIDs: ["pack-1"],
            defaultTextSize: .legacyExtraLarge,
            synonymLimit: 3
        ).repaired(availablePackIDs: ["pack-1"])
        XCTAssertEqual(repaired.defaultTextSize, .comfortable)
        XCTAssertEqual(repaired.schemaVersion, 3)
    }

    func testNewExtraLargePreferenceRemainsAvailable() {
        let repaired = IELTSGlancePreferences(
            schemaVersion: 3,
            selectedPackIDs: ["pack-1"],
            defaultTextSize: .extraLarge,
            synonymLimit: 3
        ).repaired(availablePackIDs: ["pack-1"])
        XCTAssertEqual(repaired.defaultTextSize, .extraLarge)
        XCTAssertEqual(repaired.schemaVersion, 3)
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

    func testDuplicateIDsInFutureDataDoNotCrashStateMapping() throws {
        let (store, defaults) = try makeStore()
        defer { defaults.removePersistentDomain(forName: defaultsSuiteName(defaults)) }
        let baseWords = Array(WordRepository().load().words.prefix(5))
        let duplicatedWords = baseWords + [baseWords[0]]
        let state = WidgetDisplayState(wordIDs: baseWords.map(\.id))

        let resolved = store.words(for: state, in: duplicatedWords)

        XCTAssertEqual(resolved.map(\.id), baseWords.map(\.id))
    }

    private func makeStore() throws -> (WordStateStore, UserDefaults) {
        let suite = "IELTSGlanceTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            throw XCTSkip("Unable to create isolated UserDefaults suite")
        }
        defaults.set(suite, forKey: "IELTSGlanceTestsSuiteName")
        return (WordStateStore(defaults: defaults), defaults)
    }

    private func defaultsSuiteName(_ defaults: UserDefaults) -> String {
        defaults.string(forKey: "IELTSGlanceTestsSuiteName") ?? "IELTSGlanceTests"
    }
}
