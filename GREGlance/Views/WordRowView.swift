import SwiftUI

struct WordRowView: View {
    let word: GREWord
    let position: Int
    let onReplace: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(word.word)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(word.partOfSpeech)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(word.chineseMeaning)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Text(word.synonyms.prefix(3).joined(separator: "  ·  "))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Button(action: onReplace) {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("换一个词")
                .accessibilityLabel("Replace \(word.word) with another word")
            }

            Text(word.exampleSentence)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityLabel("Example: \(word.exampleSentence)")
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Word \(position + 1): \(word.word), \(word.partOfSpeech), \(word.chineseMeaning)")
    }
}
