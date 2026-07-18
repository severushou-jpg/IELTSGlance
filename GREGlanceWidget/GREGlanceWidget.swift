import AppIntents
import SwiftUI
import WidgetKit

struct GREGlanceWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "GRE Glance Display"
    static let description = IntentDescription("Choose the text size for this Widget.")

    @Parameter(title: "Text Size", default: .followApp)
    var textSize: WidgetTextSize
}

struct GREGlanceWidgetEntry: TimelineEntry {
    let date: Date
    let words: [GREWord]
    let issue: String?
    let textSize: WidgetTextSize
    let synonymLimit: Int
}

struct GREGlanceTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GREGlanceWidgetEntry {
        GREGlanceWidgetEntry(
            date: Date(),
            words: GREWord.fallbackWords,
            issue: nil,
            textSize: .comfortable,
            synonymLimit: 3
        )
    }

    func snapshot(for configuration: GREGlanceWidgetConfigurationIntent, in context: Context) async -> GREGlanceWidgetEntry {
        makeEntry(configuration: configuration, usePreviewData: context.isPreview)
    }

    func timeline(for configuration: GREGlanceWidgetConfigurationIntent, in context: Context) async -> Timeline<GREGlanceWidgetEntry> {
        Timeline(entries: [makeEntry(configuration: configuration, usePreviewData: false)], policy: .never)
    }

    private func makeEntry(
        configuration: GREGlanceWidgetConfigurationIntent,
        usePreviewData: Bool
    ) -> GREGlanceWidgetEntry {
        let snapshot = WordRepository().load()
        let preferences = SharedPreferencesStore().load(availablePackIDs: snapshot.packIDs)
        let resolvedSize = configuration.textSize.resolved(defaultSize: preferences.defaultTextSize)

        if usePreviewData {
            return GREGlanceWidgetEntry(
                date: Date(),
                words: Array(snapshot.words.prefix(SharedConstants.displayedWordCount)),
                issue: nil,
                textSize: resolvedSize,
                synonymLimit: preferences.synonymLimit
            )
        }

        let words = snapshot.words(selectedPackIDs: preferences.selectedPackIDs)
        let stateStore = WordStateStore()
        let state = stateStore.currentState(words: words)
        return GREGlanceWidgetEntry(
            date: Date(),
            words: stateStore.words(for: state, in: words),
            issue: snapshot.issue,
            textSize: resolvedSize,
            synonymLimit: preferences.synonymLimit
        )
    }
}

struct GREGlanceWidgetView: View {
    let entry: GREGlanceWidgetEntry

    var body: some View {
        if entry.words.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                header

                ForEach(Array(entry.words.enumerated()), id: \.element.id) { index, word in
                    WidgetWordRow(
                        word: word,
                        position: index,
                        textSize: entry.textSize,
                        synonymLimit: entry.synonymLimit
                    )
                    if index < entry.words.count - 1 {
                        Divider().opacity(0.5)
                    }
                }

                Spacer(minLength: 2)
                Divider().opacity(0.5)
                footer
            }
            .padding(12)
        }
    }

    private var header: some View {
        HStack {
            Label("GRE Glance", systemImage: "rectangle.stack.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(entry.words.count) words · local only")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var footer: some View {
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

            Button(intent: ShuffleAllWordsIntent()) {
                Label("Shuffle All", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11.5, weight: .medium))
                    .padding(.horizontal, 5)
                    .frame(minHeight: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Shuffle all GRE words")
        }
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.book.closed")
                .font(.title2)
            Text("无法加载本地词库")
                .font(.headline)
            Text(entry.issue ?? "请打开 GRE Glance 检查数据文件。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct WidgetWordRow: View {
    let word: GREWord
    let position: Int
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
        Button(intent: ReplaceWordIntent(position: position, expectedWordID: word.id)) {
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

struct GREGlanceWidget: Widget {
    let kind = SharedConstants.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GREGlanceWidgetConfigurationIntent.self,
            provider: GREGlanceTimelineProvider()
        ) { entry in
            GREGlanceWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("GRE Glance")
        .description("Five quiet GRE words from your selected packs.")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    GREGlanceWidget()
} timeline: {
    GREGlanceWidgetEntry(
        date: Date(),
        words: GREWord.fallbackWords,
        issue: nil,
        textSize: .comfortable,
        synonymLimit: 3
    )
}
