import Foundation

struct VocabularyCatalog: Codable, Hashable, Sendable {
    var schemaVersion: Int
    var exams: [VocabularyExam]

    init(schemaVersion: Int = 1, exams: [VocabularyExam]) {
        self.schemaVersion = schemaVersion
        self.exams = exams
    }

    var defaultExam: VocabularyExam? {
        exams.sorted { $0.order < $1.order }.first
    }

    static func legacyIELTS(packs: [VocabularyPack]) -> VocabularyCatalog {
        VocabularyCatalog(
            exams: [
                VocabularyExam(
                    id: SharedConstants.legacyIELTSExamID,
                    name: "IELTS",
                    subtitle: "雅思考试核心词汇",
                    systemImage: "graduationcap.fill",
                    order: 1,
                    packs: packs
                )
            ]
        )
    }

    static let fallback = VocabularyCatalog(
        exams: [
            VocabularyExam(
                id: "fallback",
                name: "安全示例",
                subtitle: "词库加载失败时使用",
                systemImage: "exclamationmark.triangle.fill",
                order: 1,
                packs: [.fallback]
            )
        ]
    )
}

struct VocabularyExam: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String
    let systemImage: String?
    let order: Int
    let packs: [VocabularyPack]

    var iconName: String { systemImage ?? "graduationcap.fill" }

    var wordCount: Int {
        packs.reduce(0) { $0 + $1.words.count }
    }
}
