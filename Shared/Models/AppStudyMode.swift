import Foundation

enum AppStudyMode: String, CaseIterable, Identifiable, Sendable {
    case glance
    case sprint

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .glance: "小组件 Glance"
        case .sprint: "突击扫词"
        }
    }
}

enum SprintAccentPalette: String, CaseIterable, Identifiable, Sendable {
    case fresh
    case ember
    case violet
    case steel

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fresh: "清醒绿"
        case .ember: "冲刺橙"
        case .violet: "记忆紫"
        case .steel: "冷静蓝"
        }
    }
}

struct SprintPackState: Equatable, Sendable {
    let packID: String
    var targetRounds: Int
    var completedRounds: Int
    var currentRoundWordIDs: [String]
    var cursor: Int
    var reviewLaterWordIDs: [String]

    init(packID: String, wordIDs: [String], targetRounds: Int) {
        self.packID = packID
        self.targetRounds = targetRounds
        completedRounds = 0
        currentRoundWordIDs = wordIDs.shuffled()
        cursor = 0
        reviewLaterWordIDs = []
    }

    var isComplete: Bool {
        completedRounds >= targetRounds
    }

    var isFinalRound: Bool {
        completedRounds == targetRounds - 1
    }

    var currentRoundNumber: Int {
        min(completedRounds + 1, targetRounds)
    }

    var progressFraction: Double {
        guard !currentRoundWordIDs.isEmpty else { return 0 }
        return min(Double(cursor) / Double(currentRoundWordIDs.count), 1)
    }

    mutating func reset(wordIDs: [String], targetRounds: Int) {
        self.targetRounds = targetRounds
        completedRounds = 0
        currentRoundWordIDs = wordIDs.shuffled()
        cursor = 0
        reviewLaterWordIDs = []
    }

    mutating func visibleWordIDs(count: Int) -> [String] {
        guard !isComplete, count > 0 else { return [] }
        advanceRoundIfNeeded()
        return Array(currentRoundWordIDs.dropFirst(cursor).prefix(count))
    }

    mutating func advance(count: Int, allWordIDs: [String]) {
        guard !isComplete else { return }
        cursor += max(count, 0)
        advanceRoundIfNeeded(allWordIDs: allWordIDs)
    }

    mutating func markReviewLater(wordID: String) {
        guard isFinalRound, !reviewLaterWordIDs.contains(wordID) else { return }
        reviewLaterWordIDs.append(wordID)
    }

    mutating func unmarkReviewLater(wordID: String) {
        reviewLaterWordIDs.removeAll { $0 == wordID }
    }

    private mutating func advanceRoundIfNeeded(allWordIDs: [String]? = nil) {
        while cursor >= currentRoundWordIDs.count, !isComplete {
            completedRounds += 1
            cursor = 0
            guard !isComplete else { break }
            currentRoundWordIDs = (allWordIDs ?? currentRoundWordIDs).shuffled()
        }
    }
}
