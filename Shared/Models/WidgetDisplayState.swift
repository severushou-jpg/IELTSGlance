import Foundation

struct WidgetDisplayState: Codable, Equatable, Sendable {
    var wordIDs: [String]
    var revision: Int
    var updatedAt: Date

    init(wordIDs: [String], revision: Int = 0, updatedAt: Date = Date()) {
        self.wordIDs = wordIDs
        self.revision = revision
        self.updatedAt = updatedAt
    }
}
