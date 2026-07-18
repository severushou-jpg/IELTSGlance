import Foundation

struct VocabularyPack: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let order: Int
    let words: [GREWord]

    var wordRangeDescription: String {
        let start = (order - 1) * 100 + 1
        let end = start + max(words.count - 1, 0)
        return "Words \(start)–\(end)"
    }

    static let fallback = VocabularyPack(
        id: "fallback",
        name: "安全示例",
        subtitle: "词库加载失败时使用",
        order: 1,
        words: GREWord.fallbackWords
    )
}
