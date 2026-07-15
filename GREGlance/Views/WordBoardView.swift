import SwiftUI

struct WordBoardView: View {
    let words: [GREWord]
    let onReplace: (Int) -> Void
    let onShuffle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                WordRowView(word: word, position: index) {
                    onReplace(index)
                }

                if index < words.count - 1 {
                    Divider()
                }
            }

            Divider()

            HStack {
                Text("看过即可更换，不记录掌握状态")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button(action: onShuffle) {
                    Label("Shuffle All", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Shuffle all GRE words")
            }
            .padding(.top, 12)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.separator.opacity(0.55), lineWidth: 1)
        }
    }
}
