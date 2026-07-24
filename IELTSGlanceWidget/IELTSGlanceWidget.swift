import AppIntents
import SwiftUI
import WidgetKit

struct IELTSGlanceWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "IELTS Glance Display"
    static let description = IntentDescription("Choose the text size and IELTS study topics for this Widget.")

    @Parameter(title: "Text Size", default: .comfortable)
    var textSize: WidgetTextSize

    @Parameter(title: "Exam Type", default: .ielts)
    var exam: WidgetVocabularyExam

    @Parameter(title: "Study Topics", default: [.pack01])
    var wordPacks: [WidgetVocabularyPack]
}

struct IELTSGlanceWidgetEntry: TimelineEntry {
    let date: Date
    let words: [IELTSWord]
    let issue: String?
    let textSize: WidgetTextSize
    let synonymLimit: Int
    let revision: Int
    let selectedExamID: String
    let selectedPackIDs: [String]
}

struct IELTSGlanceTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> IELTSGlanceWidgetEntry {
        IELTSGlanceWidgetEntry(
            date: Date(),
            words: IELTSWord.fallbackWords,
            issue: nil,
            textSize: .comfortable,
            synonymLimit: 3,
            revision: 0,
            selectedExamID: WidgetVocabularyExam.ielts.rawValue,
            selectedPackIDs: [WidgetVocabularyPack.pack01.rawValue]
        )
    }

    func snapshot(for configuration: IELTSGlanceWidgetConfigurationIntent, in context: Context) async -> IELTSGlanceWidgetEntry {
        makeEntry(configuration: configuration, usePreviewData: context.isPreview)
    }

    func timeline(for configuration: IELTSGlanceWidgetConfigurationIntent, in context: Context) async -> Timeline<IELTSGlanceWidgetEntry> {
        Timeline(entries: [makeEntry(configuration: configuration, usePreviewData: false)], policy: .never)
    }

    private func makeEntry(
        configuration: IELTSGlanceWidgetConfigurationIntent,
        usePreviewData: Bool
    ) -> IELTSGlanceWidgetEntry {
        let snapshot = WordRepository().load()
        let selectedPackIDs = configuration.wordPacks.isEmpty
            ? Array(snapshot.packIDs.prefix(1))
            : configuration.wordPacks.map(\.rawValue)
        let selectedExamID = configuration.exam.rawValue
        let resolvedSize = configuration.textSize.resolved(defaultSize: .comfortable)

        if usePreviewData {
            return IELTSGlanceWidgetEntry(
                date: Date(),
                words: Array(snapshot.words.prefix(SharedConstants.displayedWordCount)),
                issue: nil,
                textSize: resolvedSize,
                synonymLimit: 3,
                revision: 0,
                selectedExamID: selectedExamID,
                selectedPackIDs: selectedPackIDs
            )
        }

        let words = snapshot.words(selectedExamID: selectedExamID, selectedPackIDs: selectedPackIDs)
        let stateStore = WordStateStore()
        let state = stateStore.currentState(words: words)
        return IELTSGlanceWidgetEntry(
            date: Date(),
            words: stateStore.words(for: state, in: words),
            issue: snapshot.issue,
            textSize: resolvedSize,
            synonymLimit: 3,
            revision: state.revision,
            selectedExamID: selectedExamID,
            selectedPackIDs: selectedPackIDs
        )
    }
}

struct IELTSGlanceWidgetView: View {
    let entry: IELTSGlanceWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.words.isEmpty {
            emptyState
        } else {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            default:
                largeWidget
            }
        }
    }

    private var largeWidget: some View {
        VStack(spacing: 0) {
            header(visibleCount: min(entry.words.count, SharedConstants.displayedWordCount))

            ForEach(Array(entry.words.prefix(SharedConstants.displayedWordCount).enumerated()), id: \.element.id) { index, word in
                WidgetWordRow(
                    word: word,
                    position: index,
                    visibleWordIDs: entry.words.map(\.id),
                    revision: entry.revision,
                    selectedExamID: entry.selectedExamID,
                    selectedPackIDs: entry.selectedPackIDs,
                    textSize: entry.textSize,
                    synonymLimit: entry.synonymLimit
                )
                if index < min(entry.words.count, SharedConstants.displayedWordCount) - 1 {
                    Divider().opacity(0.5)
                }
            }

            Spacer(minLength: 2)
            Divider().opacity(0.5)
            largeFooter
        }
        .padding(12)
    }

    private var mediumWidget: some View {
        VStack(spacing: 0) {
            header(visibleCount: min(entry.words.count, 2))

            ForEach(Array(entry.words.prefix(2).enumerated()), id: \.element.id) { index, word in
                MediumWidgetWordRow(
                    word: word,
                    position: index,
                    visibleWordIDs: entry.words.map(\.id),
                    revision: entry.revision,
                    selectedExamID: entry.selectedExamID,
                    selectedPackIDs: entry.selectedPackIDs,
                    textSize: entry.textSize,
                    synonymLimit: entry.synonymLimit
                )
                if index == 0, entry.words.count > 1 {
                    Divider().opacity(0.5)
                }
            }

            Spacer(minLength: 1)
            Divider().opacity(0.5)
            compactFooter
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
    }

    @ViewBuilder
    private var smallWidget: some View {
        if let word = entry.words.first {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Label("IELTS Glance", systemImage: "rectangle.stack.fill")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    shuffleButton(labelStyle: .iconOnly)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(word.word)
                        .font(.system(size: smallWordFontSize, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(word.partOfSpeech)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(word.chineseMeaning)
                            .font(.system(size: smallMeaningFontSize, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Text(word.synonyms.prefix(2).joined(separator: " · "))
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 2)

                Text(word.exampleSentence)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 2)

                HStack {
                    Text("完全离线")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    replaceButton(for: word, at: 0, showsLabel: true)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    private func header(visibleCount: Int) -> some View {
        HStack {
            Label("IELTS Glance", systemImage: "rectangle.stack.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(visibleCount) \(visibleCount == 1 ? "word" : "words") · local only")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var largeFooter: some View {
        HStack {
            if let issue = entry.issue {
                Label(issue, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("完全离线 · 不记录学习历史")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            shuffleButton(labelStyle: .titleAndIcon)
        }
        .padding(.top, 4)
    }

    private var compactFooter: some View {
        HStack {
            Text("完全离线 · 不记录学习历史")
                .font(.system(size: 9.5))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            shuffleButton(labelStyle: .titleAndIcon)
        }
        .padding(.top, 3)
    }

    private func shuffleButton(labelStyle: LabelStyleMode) -> some View {
        Button(intent: ShuffleAllWordsIntent(
            expectedRevision: entry.revision,
            visibleWordIDs: entry.words.map(\.id),
            selectedExamID: entry.selectedExamID,
            selectedPackIDs: entry.selectedPackIDs
        )) {
            Group {
                if labelStyle == .iconOnly {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .frame(width: 24, height: 22)
                } else {
                    Label("Shuffle All", systemImage: "arrow.triangle.2.circlepath")
                        .padding(.horizontal, 4)
                        .frame(minHeight: 24)
                }
            }
            .font(.system(size: 11.5, weight: .medium))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Shuffle all IELTS words")
    }

    private func replaceButton(for word: IELTSWord, at position: Int, showsLabel: Bool) -> some View {
        Button(intent: ReplaceWordIntent(
            position: position,
            expectedWordID: word.id,
            expectedRevision: entry.revision,
            visibleWordIDs: entry.words.map(\.id),
            selectedExamID: entry.selectedExamID,
            selectedPackIDs: entry.selectedPackIDs
        )) {
            Group {
                if showsLabel {
                    Label("换一个", systemImage: "checkmark.circle")
                        .padding(.horizontal, 4)
                } else {
                    Image(systemName: "checkmark.circle")
                }
            }
            .font(.system(size: 11.5, weight: .medium))
            .frame(minHeight: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Replace \(word.word) with another word")
    }

    private var smallWordFontSize: CGFloat {
        switch entry.textSize.resolvedDefault {
        case .comfortable, .followApp, .legacyExtraLarge: 20
        case .large: 21
        case .extraLarge: 22
        }
    }

    private var smallMeaningFontSize: CGFloat {
        switch entry.textSize.resolvedDefault {
        case .comfortable, .followApp, .legacyExtraLarge: 13
        case .large: 14
        case .extraLarge: 15
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.book.closed")
                .font(.title2)
            Text("无法加载本地词库")
                .font(.headline)
            Text(entry.issue ?? "请打开 IELTS Glance 检查数据文件。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum LabelStyleMode: Equatable {
    case iconOnly
    case titleAndIcon
}

private struct MediumWidgetWordRow: View {
    let word: IELTSWord
    let position: Int
    let visibleWordIDs: [String]
    let revision: Int
    let selectedExamID: String
    let selectedPackIDs: [String]
    let textSize: WidgetTextSize
    let synonymLimit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(word.word)
                    .font(.system(size: textSize.wordFontSize, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)

                Text(word.partOfSpeech)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(word.chineseMeaning)
                    .font(.system(size: textSize.meaningFontSize, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(2)

                Spacer(minLength: 2)

                ViewThatFits(in: .horizontal) {
                    synonymText(count: min(synonymLimit, 2))
                    synonymText(count: 1)
                    Color.clear.frame(width: 0, height: 1)
                }

                replaceButton
            }
            .frame(height: 22)
            .clipped()

            Text(word.exampleSentence)
                .font(.system(size: textSize.exampleFontSize))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, 2)
        .frame(height: 42)
        .clipped()
        .accessibilityElement(children: .contain)
    }

    private var replaceButton: some View {
        Button(intent: ReplaceWordIntent(
            position: position,
            expectedWordID: word.id,
            expectedRevision: revision,
            visibleWordIDs: visibleWordIDs,
            selectedExamID: selectedExamID,
            selectedPackIDs: selectedPackIDs
        )) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 16.5, weight: .medium))
                .frame(width: 27, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Replace \(word.word) with another word")
    }

    private func synonymText(count: Int) -> some View {
        Text(word.synonyms.prefix(count).joined(separator: " · "))
            .font(.system(size: 10.25))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}

private struct WidgetWordRow: View {
    let word: IELTSWord
    let position: Int
    let visibleWordIDs: [String]
    let revision: Int
    let selectedExamID: String
    let selectedPackIDs: [String]
    let textSize: WidgetTextSize
    let synonymLimit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(word.word)
                    .font(.system(size: textSize.wordFontSize, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(1)
                    .allowsTightening(false)
                    .fixedSize(horizontal: true, vertical: true)

                Text(word.partOfSpeech)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(1)
                    .allowsTightening(false)
                    .fixedSize(horizontal: true, vertical: true)

                Text(word.chineseMeaning)
                    .font(.system(size: textSize.meaningFontSize, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(1)
                    .allowsTightening(false)
                    .truncationMode(.tail)
                    .layoutPriority(3)

                Spacer(minLength: 3)

                ViewThatFits(in: .horizontal) {
                    synonymText(count: min(synonymLimit, 3))
                    if synonymLimit > 1 {
                        synonymText(count: min(synonymLimit, 2))
                    }
                    synonymText(count: 1)
                    Color.clear.frame(width: 0, height: 1)
                }

                replaceButton
            }
            .frame(height: 26)
            .clipped()

            Text(word.exampleSentence)
                .font(.system(size: textSize.exampleFontSize))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(1)
                .allowsTightening(false)
                .truncationMode(.tail)
        }
        .padding(.vertical, 2)
        .frame(height: 48)
        .clipped()
        .accessibilityElement(children: .contain)
    }

    private var replaceButton: some View {
        Button(intent: ReplaceWordIntent(
            position: position,
            expectedWordID: word.id,
            expectedRevision: revision,
            visibleWordIDs: visibleWordIDs,
            selectedExamID: selectedExamID,
            selectedPackIDs: selectedPackIDs
        )) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 17, weight: .medium))
                .frame(width: 28, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Replace \(word.word) with another word")
    }

    private func synonymText(count: Int) -> some View {
        Text(word.synonyms.prefix(count).joined(separator: " · "))
            .font(.system(size: 10.75))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}

struct IELTSGlanceWidget: Widget {
    let kind = SharedConstants.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: IELTSGlanceWidgetConfigurationIntent.self,
            provider: IELTSGlanceTimelineProvider()
        ) { entry in
            IELTSGlanceWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("IELTS Glance")
        .description("One, two, or five quiet IELTS words from your selected packs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    IELTSGlanceWidget()
} timeline: {
    IELTSGlanceWidgetEntry(
        date: Date(),
        words: IELTSWord.fallbackWords,
        issue: nil,
        textSize: .comfortable,
        synonymLimit: 3,
        revision: 0,
        selectedExamID: WidgetVocabularyExam.ielts.rawValue,
        selectedPackIDs: [WidgetVocabularyPack.pack01.rawValue]
    )
}

#Preview(as: .systemMedium) {
    IELTSGlanceWidget()
} timeline: {
    IELTSGlanceWidgetEntry(
        date: Date(),
        words: IELTSWord.fallbackWords,
        issue: nil,
        textSize: .comfortable,
        synonymLimit: 3,
        revision: 0,
        selectedExamID: WidgetVocabularyExam.ielts.rawValue,
        selectedPackIDs: [WidgetVocabularyPack.pack01.rawValue]
    )
}

#Preview(as: .systemLarge) {
    IELTSGlanceWidget()
} timeline: {
    IELTSGlanceWidgetEntry(
        date: Date(),
        words: IELTSWord.fallbackWords,
        issue: nil,
        textSize: .comfortable,
        synonymLimit: 3,
        revision: 0,
        selectedExamID: WidgetVocabularyExam.ielts.rawValue,
        selectedPackIDs: [WidgetVocabularyPack.pack01.rawValue]
    )
}
