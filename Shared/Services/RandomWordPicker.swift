import Foundation

struct RandomWordPicker: Sendable {
    func pickUniqueIDs(count: Int, from words: [GREWord], excluding: Set<String> = []) -> [String] {
        guard count > 0 else { return [] }
        let candidates = words.filter { !excluding.contains($0.id) }
        return Array(candidates.shuffled().prefix(count)).map(\.id)
    }

    func replacementID(
        from words: [GREWord],
        excluding currentOtherIDs: Set<String>,
        avoiding replacedID: String
    ) -> String? {
        let preferred = words.filter {
            !currentOtherIDs.contains($0.id) && $0.id != replacedID
        }
        if let replacement = preferred.randomElement() {
            return replacement.id
        }

        return words.first { !currentOtherIDs.contains($0.id) }?.id
    }
}
