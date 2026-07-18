import SwiftUI

struct PackSelectionView: View {
    let store: AppWordStore

    private let columns = [GridItem(.adaptive(minimum: 132, maximum: 180), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("选择词包")
                        .font(.headline)
                    Text("随机刷新只会从已选择的词包中抽取。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("已选 \(store.selectedPackIDs.count)/\(store.packs.count) 包 · \(store.selectedWordCount) 词")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button("全选", action: store.selectAllPacks)
                    .buttonStyle(.borderless)
                    .disabled(store.selectedPackIDs.count == store.packs.count)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(store.packs) { pack in
                    PackButton(
                        pack: pack,
                        isSelected: store.selectedPackIDs.contains(pack.id),
                        canDeselect: store.selectedPackIDs.count > 1,
                        onToggle: { store.togglePack(pack.id) },
                        onSelectOnly: { store.selectOnlyPack(pack.id) }
                    )
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

private struct PackButton: View {
    let pack: VocabularyPack
    let isSelected: Bool
    let canDeselect: Bool
    let onToggle: () -> Void
    let onSelectOnly: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                VStack(alignment: .leading, spacing: 1) {
                    Text(pack.name)
                        .font(.callout.weight(.medium))
                    Text(pack.wordRangeDescription)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(9)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.15))
        }
        .disabled(isSelected && !canDeselect)
        .help("点按切换；右键可仅选择此包")
        .accessibilityLabel("\(pack.name)，\(isSelected ? "已选择" : "未选择")，100 个词")
        .contextMenu {
            Button("仅选择此词包", action: onSelectOnly)
        }
    }
}
