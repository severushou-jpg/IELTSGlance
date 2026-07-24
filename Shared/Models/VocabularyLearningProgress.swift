import Foundation

enum VocabularyLearningStatus: String, Codable, Sendable {
    case seen
    case favorite
    case reviewLater
    case mastered
}

struct VocabularyLearningRecord: Codable, Equatable, Sendable {
    var wordID: String
    var status: VocabularyLearningStatus
    var seenCount: Int
    var updatedAt: Date

    init(
        wordID: String,
        status: VocabularyLearningStatus = .seen,
        seenCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.wordID = wordID
        self.status = status
        self.seenCount = seenCount
        self.updatedAt = updatedAt
    }
}

struct VocabularyLearningProgress: Codable, Equatable, Sendable {
    var recordsByWordID: [String: VocabularyLearningRecord]

    init(recordsByWordID: [String: VocabularyLearningRecord] = [:]) {
        self.recordsByWordID = recordsByWordID
    }
}
