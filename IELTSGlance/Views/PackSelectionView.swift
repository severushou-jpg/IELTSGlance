import SwiftUI

struct PackSelectionView: View {
    let store: AppWordStore

    private let columns = [GridItem(.adaptive(minimum: 240, maximum: 310), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("选择词包")
                        .font(.headline)
                    Text("按备考任务和高频话题选择；随机刷新只从已选主题抽取。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ExamSelectionControl(
                    options: store.examSelectionOptions,
                    selectedExamID: store.selectedExamID,
                    onSelect: store.setSelectedExam
                )
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

private struct ExamSelectionControl: View {
    let options: [ExamSelectionOption]
    let selectedExamID: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                Button(action: { onSelect(option.id) }) {
                    Text(option.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .frame(width: 38)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .foregroundStyle(foregroundStyle(for: option))
                .background(backgroundStyle(for: option), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(borderStyle(for: option), lineWidth: 1)
                }
                .disabled(!option.isAvailable)
                .help(option.isAvailable ? "切换到\(option.title)词库" : "\(option.title)词库待加入")
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func isSelected(_ option: ExamSelectionOption) -> Bool {
        option.id == selectedExamID
    }

    private func foregroundStyle(for option: ExamSelectionOption) -> AnyShapeStyle {
        guard option.isAvailable else { return AnyShapeStyle(.tertiary) }
        return isSelected(option) ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary)
    }

    private func backgroundStyle(for option: ExamSelectionOption) -> AnyShapeStyle {
        guard option.isAvailable else { return AnyShapeStyle(Color.secondary.opacity(0.05)) }
        return isSelected(option)
            ? AnyShapeStyle(Color.accentColor)
            : AnyShapeStyle(Color.secondary.opacity(0.08))
    }

    private func borderStyle(for option: ExamSelectionOption) -> AnyShapeStyle {
        guard option.isAvailable else { return AnyShapeStyle(Color.secondary.opacity(0.12)) }
        return isSelected(option)
            ? AnyShapeStyle(Color.accentColor.opacity(0.7))
            : AnyShapeStyle(Color.secondary.opacity(0.15))
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
                PackIcon(name: pack.iconName, isSelected: isSelected)
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(.callout.weight(.medium))
                    Text(pack.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(pack.wordCountDescription)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
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
        .accessibilityLabel("\(pack.name)，\(pack.subtitle)，\(isSelected ? "已选择" : "未选择")，\(pack.words.count) 个词")
        .contextMenu {
            Button("仅选择此词包", action: onSelectOnly)
        }
    }
}

private struct PackIcon: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        Image(systemName: name)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .frame(width: 26, height: 26)
            .background(iconBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(iconBorder, lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    private var iconBackground: Color {
        isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08)
    }

    private var iconBorder: Color {
        isSelected ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.12)
    }
}
