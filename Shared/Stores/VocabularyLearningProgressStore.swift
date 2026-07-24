import Foundation

final class VocabularyLearningProgressStore: @unchecked Sendable {
    private let storage: SharedJSONFileStorage<VocabularyLearningProgress>

    init(defaults: UserDefaults? = nil) {
        let resolvedDefaults = defaults ?? SharedConstants.stateDefaults()
        storage = SharedJSONFileStorage(
            fileName: "learning-progress-v1.json",
            defaultsKey: SharedConstants.learningProgressDefaultsKey,
            defaults: resolvedDefaults,
            lockURL: defaults == nil ? SharedConstants.defaultsStorageLockURL() : nil
        )
    }

    func load() -> VocabularyLearningProgress {
        storage.update { stored in stored ?? VocabularyLearningProgress() }
    }

    @discardableResult
    func recordSeen(wordID: String) -> VocabularyLearningRecord {
        updateRecord(wordID: wordID) { record in
            record.status = record.status == .mastered ? .mastered : .seen
            record.seenCount += 1
            record.updatedAt = Date()
        }
    }

    @discardableResult
    func setStatus(_ status: VocabularyLearningStatus, wordID: String) -> VocabularyLearningRecord {
        updateRecord(wordID: wordID) { record in
            record.status = status
            record.updatedAt = Date()
        }
    }

    @discardableResult
    func clearStatus(_ status: VocabularyLearningStatus, wordID: String) -> VocabularyLearningRecord? {
        var updatedRecord: VocabularyLearningRecord?
        storage.update { stored in
            var progress = stored ?? VocabularyLearningProgress()
            guard var record = progress.recordsByWordID[wordID],
                  record.status == status else {
                return progress
            }

            if record.seenCount > 0 {
                record.status = .seen
                record.updatedAt = Date()
                progress.recordsByWordID[wordID] = record
                updatedRecord = record
            } else {
                progress.recordsByWordID.removeValue(forKey: wordID)
            }
            return progress
        }
        return updatedRecord
    }

    func record(for wordID: String) -> VocabularyLearningRecord? {
        load().recordsByWordID[wordID]
    }

    private func updateRecord(
        wordID: String,
        _ transform: (inout VocabularyLearningRecord) -> Void
    ) -> VocabularyLearningRecord {
        var updatedRecord = VocabularyLearningRecord(wordID: wordID)
        storage.update { stored in
            var progress = stored ?? VocabularyLearningProgress()
            var record = progress.recordsByWordID[wordID] ?? VocabularyLearningRecord(wordID: wordID)
            transform(&record)
            progress.recordsByWordID[wordID] = record
            updatedRecord = record
            return progress
        }
        return updatedRecord
    }
}
