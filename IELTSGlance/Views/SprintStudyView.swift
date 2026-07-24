import SwiftUI

struct SprintStudyView: View {
    let store: AppWordStore
    @State private var showsReviewLaterLibrary = false

    private let columns = [GridItem(.adaptive(minimum: 250, maximum: 320), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            controls
            if showsReviewLaterLibrary || !store.reviewLaterWords.isEmpty {
                ReviewLaterLibraryView(
                    words: store.reviewLaterWords,
                    textSize: store.defaultTextSize,
                    synonymLimit: store.synonymLimit,
                    onRemove: store.removeReviewLater
                )
            }
            packProgressGrid
            activePackPanel
        }
    }

    private var controls: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("突击扫词")
                    .font(.headline)
                Text("每一轮按词包乱序扫完；同一轮内不会重复出现单词。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .layoutPriority(1)

            Spacer()

            HStack(alignment: .center, spacing: 12) {
                Picker("轮数", selection: Binding(
                    get: { store.sprintRoundTarget },
                    set: store.setSprintRoundTarget
                )) {
                    ForEach(store.sprintRoundOptions, id: \.self) { round in
                        Text("\(round) 轮").tag(round)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                .fixedSize(horizontal: true, vertical: false)

                Picker("色卡", selection: Binding(
                    get: { store.sprintPalette },
                    set: store.setSprintPalette
                )) {
                    ForEach(SprintAccentPalette.allCases) { palette in
                        Text(palette.displayName).tag(palette)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 118)
                .fixedSize(horizontal: true, vertical: false)

                Button(action: { showsReviewLaterLibrary.toggle() }) {
                    ReviewLaterButtonLabel(
                        count: store.reviewLaterCount,
                        isShowingLibrary: showsReviewLaterLibrary
                    )
                }
                .buttonStyle(.borderless)
                .frame(width: 152, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)
                .help("打开稍后复习库")

                Button(action: store.resetSprintSession) {
                    Label("重开", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)
                .frame(width: 64, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 630, alignment: .trailing)
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var packProgressGrid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(store.packs.filter { store.selectedPackIDs.contains($0.id) }) { pack in
                SprintPackProgressButton(
                    pack: pack,
                    state: store.sprintPackStates[pack.id],
                    palette: store.sprintPalette,
                    isActive: store.activeSprintPack?.id == pack.id,
                    onSelect: { store.selectSprintPack(pack.id) }
                )
            }
        }
    }

    private struct ReviewLaterButtonLabel: View {
        let count: Int
        let isShowingLibrary: Bool

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: isShowingLibrary ? "tray.full.fill" : "tray.full")
                    .frame(width: 16)

                Text("稍后复习")
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 42, alignment: .trailing)
            }
            .frame(width: 140, alignment: .leading)
        }
    }

    @ViewBuilder
    private var activePackPanel: some View {
        if let pack = store.activeSprintPack,
           let state = store.activeSprintState {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pack.name)
                            .font(.title2.weight(.semibold))
                        Text("第 \(state.currentRoundNumber) / \(state.targetRounds) 轮 · 已扫 \(state.completedRounds) 轮 · \(state.reviewLaterWordIDs.count) 个稍后复习")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: store.advanceSprintBatch) {
                        Label(state.isComplete ? "已完成" : "下一组", systemImage: "arrow.forward.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(state.isComplete || store.sprintDisplayedWords.isEmpty)
                }

                if state.isComplete {
                    SprintCompleteView(state: state, palette: store.sprintPalette)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.sprintDisplayedWords) { word in
                            SprintWordRowView(
                                word: word,
                                textSize: store.defaultTextSize,
                                synonymLimit: store.synonymLimit,
                                canReviewLater: state.isFinalRound,
                                isMarkedReviewLater: state.reviewLaterWordIDs.contains(word.id),
                                onReviewLater: { store.toggleSprintReviewLater(word.id) }
                            )
                            if word.id != store.sprintDisplayedWords.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.separator.opacity(0.45), lineWidth: 1)
                    }
                }
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            EmptyStateView(message: "请选择至少一个词包开始突击扫词。")
        }
    }
}

private struct SprintPackProgressButton: View {
    let pack: VocabularyPack
    let state: SprintPackState?
    let palette: SprintAccentPalette
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                SprintProgressRing(
                    progress: state?.progressFraction ?? 0,
                    completedRounds: state?.completedRounds ?? 0,
                    targetRounds: state?.targetRounds ?? 1,
                    palette: palette
                )
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text(pack.name)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Text(pack.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(progressText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isActive ? palette.primary.opacity(0.16) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? palette.primary.opacity(0.55) : Color.secondary.opacity(0.15))
        }
    }

    private var progressText: String {
        guard let state else { return "未开始" }
        if state.isComplete { return "已完成 \(state.targetRounds) 轮" }
        return "第 \(state.currentRoundNumber) 轮 · \(Int(state.progressFraction * 100))%"
    }
}

private struct SprintProgressRing: View {
    let progress: Double
    let completedRounds: Int
    let targetRounds: Int
    let palette: SprintAccentPalette

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0.02, min(progress, 1)))
                .stroke(activeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(completedRounds)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(activeColor)
        }
        .accessibilityLabel("已完成 \(completedRounds) / \(targetRounds) 轮")
    }

    private var activeColor: Color {
        completedRounds >= targetRounds ? palette.complete : palette.color(forCompletedRounds: completedRounds)
    }
}

private struct SprintWordRowView: View {
    let word: IELTSWord
    let textSize: WidgetTextSize
    let synonymLimit: Int
    let canReviewLater: Bool
    let isMarkedReviewLater: Bool
    let onReviewLater: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.word)
                        .font(.system(size: textSize.wordFontSize + 3, weight: .semibold))
                        .lineLimit(1)
                    Text(word.partOfSpeech)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(word.chineseMeaning)
                        .font(.system(size: textSize.meaningFontSize + 1, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Text(word.synonyms.prefix(synonymLimit).joined(separator: "  ·  "))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(word.exampleSentence)
                    .font(.system(size: textSize.exampleFontSize + 1))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if canReviewLater {
                Button(action: onReviewLater) {
                    Image(systemName: isMarkedReviewLater ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isMarkedReviewLater ? Color.accentColor : Color.secondary)
                .help(isMarkedReviewLater ? "取消稍后复习" : "加入稍后复习")
            }
        }
        .padding(.vertical, 10)
    }
}

private struct ReviewLaterLibraryView: View {
    let words: [IELTSWord]
    let textSize: WidgetTextSize
    let synonymLimit: Int
    let onRemove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("稍后复习库", systemImage: "tray.full")
                    .font(.headline)
                Spacer()
                Text("\(words.count) 个词")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if words.isEmpty {
                Text("最后一轮标记的词会出现在这里。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(words) { word in
                        ReviewLaterWordRow(
                            word: word,
                            textSize: textSize,
                            synonymLimit: synonymLimit,
                            onRemove: { onRemove(word.id) }
                        )
                        if word.id != words.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.separator.opacity(0.45), lineWidth: 1)
        }
    }
}

private struct ReviewLaterWordRow: View {
    let word: IELTSWord
    let textSize: WidgetTextSize
    let synonymLimit: Int
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.word)
                        .font(.system(size: textSize.wordFontSize + 1, weight: .semibold))
                    Text(word.partOfSpeech)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(word.chineseMeaning)
                        .font(.system(size: textSize.meaningFontSize, weight: .medium))
                    Spacer()
                    Text(word.synonyms.prefix(synonymLimit).joined(separator: "  ·  "))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(word.exampleSentence)
                    .font(.system(size: textSize.exampleFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle")
                    .font(.title3)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("移出稍后复习")
        }
        .padding(.vertical, 9)
    }
}

private struct SprintCompleteView: View {
    let state: SprintPackState
    let palette: SprintAccentPalette

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 42))
                .foregroundStyle(palette.complete)
            Text("这个词包已完成 \(state.targetRounds) 轮")
                .font(.headline)
            Text("最后一轮标记了 \(state.reviewLaterWordIDs.count) 个稍后复习词。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension SprintAccentPalette {
    var primary: Color {
        switch self {
        case .fresh: .green
        case .ember: .orange
        case .violet: .purple
        case .steel: .blue
        }
    }

    var complete: Color {
        switch self {
        case .fresh: .mint
        case .ember: .red
        case .violet: .indigo
        case .steel: .cyan
        }
    }

    func color(forCompletedRounds rounds: Int) -> Color {
        let colors: [Color]
        switch self {
        case .fresh:
            colors = [.green, .mint, .teal, .cyan, .blue]
        case .ember:
            colors = [.orange, .red, .pink, .purple, .indigo]
        case .violet:
            colors = [.purple, .indigo, .blue, .teal, .mint]
        case .steel:
            colors = [.blue, .cyan, .teal, .green, .mint]
        }
        return colors[min(max(rounds, 0), colors.count - 1)]
    }
}
