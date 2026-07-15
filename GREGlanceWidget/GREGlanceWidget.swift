//
//  GREGlanceWidget.swift
//  GREGlanceWidget
//
//  Created by severushou on 2026/7/16.
//

import WidgetKit
import SwiftUI
import AppIntents

struct GREGlanceWidgetEntry: TimelineEntry {
    let date: Date
    let words: [GREWord]
    let issue: String?
}

struct GREGlanceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> GREGlanceWidgetEntry {
        GREGlanceWidgetEntry(date: Date(), words: GREWord.fallbackWords, issue: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (GREGlanceWidgetEntry) -> Void) {
        completion(makeEntry(usePreviewData: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GREGlanceWidgetEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry(usePreviewData: false)], policy: .never))
    }

    private func makeEntry(usePreviewData: Bool) -> GREGlanceWidgetEntry {
        if usePreviewData {
            return GREGlanceWidgetEntry(date: Date(), words: GREWord.fallbackWords, issue: nil)
        }

        let snapshot = WordRepository().load()
        let stateStore = WordStateStore()
        let state = stateStore.currentState(words: snapshot.words)
        return GREGlanceWidgetEntry(
            date: Date(),
            words: stateStore.words(for: state, in: snapshot.words),
            issue: snapshot.issue
        )
    }
}

struct GREGlanceWidgetView: View {
    let entry: GREGlanceWidgetEntry

    var body: some View {
        if entry.words.isEmpty {
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
        } else {
            VStack(spacing: 0) {
                HStack {
                    Label("GRE Glance", systemImage: "rectangle.stack.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("看见 · 熟悉")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 4)

                ForEach(Array(entry.words.enumerated()), id: \.element.id) { index, word in
                    widgetWordRow(word, position: index)
                    if index < entry.words.count - 1 {
                        Divider().opacity(0.55)
                    }
                }

                Spacer(minLength: 3)
                Divider().opacity(0.55)

                HStack {
                    if let issue = entry.issue {
                        Label(issue, systemImage: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("完全离线 · 不记录学习历史")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Button(intent: ShuffleAllWordsIntent()) {
                        Label("Shuffle All", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 5)
                            .frame(minHeight: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Shuffle all GRE words")
                }
                .padding(.top, 4)
            }
            .padding(12)
        }
    }

    private func widgetWordRow(_ word: GREWord, position: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(word.word)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(word.partOfSpeech)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)

                Text(word.chineseMeaning)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 4)

                Text(word.synonyms.prefix(3).joined(separator: " · "))
                    .font(.system(size: 9.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Button(intent: ReplaceWordIntent(position: position, expectedWordID: word.id)) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 24, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Replace \(word.word) with another word")
            }

            Text(word.exampleSentence)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .contain)
    }
}

struct GREGlanceWidget: Widget {
    let kind = SharedConstants.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GREGlanceTimelineProvider()) { entry in
            GREGlanceWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("GRE Glance")
        .description("Five quiet GRE words for your desktop.")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    GREGlanceWidget()
} timeline: {
    GREGlanceWidgetEntry(date: Date(), words: GREWord.fallbackWords, issue: nil)
}
