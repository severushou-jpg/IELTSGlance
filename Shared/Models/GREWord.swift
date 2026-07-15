import Foundation

struct GREWord: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let word: String
    let partOfSpeech: String
    let chineseMeaning: String
    let synonyms: [String]
    let exampleSentence: String
    let source: String?

    static let fallbackWords: [GREWord] = [
        GREWord(id: "fallback-abate", word: "abate", partOfSpeech: "v.", chineseMeaning: "减弱", synonyms: ["subside", "diminish"], exampleSentence: "The wind began to abate before dawn.", source: "Built-in fallback"),
        GREWord(id: "fallback-bolster", word: "bolster", partOfSpeech: "v.", chineseMeaning: "支持；增强", synonyms: ["support", "strengthen"], exampleSentence: "New evidence may bolster the central claim.", source: "Built-in fallback"),
        GREWord(id: "fallback-candid", word: "candid", partOfSpeech: "adj.", chineseMeaning: "坦率的", synonyms: ["frank", "forthright"], exampleSentence: "Her candid reply clarified the disagreement.", source: "Built-in fallback"),
        GREWord(id: "fallback-lucid", word: "lucid", partOfSpeech: "adj.", chineseMeaning: "清晰易懂的", synonyms: ["clear", "coherent"], exampleSentence: "The essay offers a lucid account of the theory.", source: "Built-in fallback"),
        GREWord(id: "fallback-pragmatic", word: "pragmatic", partOfSpeech: "adj.", chineseMeaning: "务实的", synonyms: ["practical", "realistic"], exampleSentence: "They chose a pragmatic solution to the shortage.", source: "Built-in fallback")
    ]
}
