//
//  ContentView.swift
//  GREGlance
//
//  Created by severushou on 2026/7/16.
//

import SwiftUI

struct ContentView: View {
    let store: AppWordStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if let issue = store.issue {
                    Label(issue, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
                }

                PackSelectionView(store: store)

                if store.displayedWords.isEmpty {
                    EmptyStateView(message: store.issue ?? "本地词库中没有可用词条。")
                } else {
                    WordBoardView(
                        words: store.displayedWords,
                        textSize: store.defaultTextSize,
                        synonymLimit: store.synonymLimit,
                        onReplace: store.replaceWord,
                        onShuffle: store.shuffleAll
                    )
                }

                InstructionsView()
                AboutView(
                    totalWordCount: store.totalWordCount,
                    stateModeDescription: store.stateModeDescription,
                    usesSharedState: store.usesSharedState,
                    usesFallbackData: store.usesFallbackData
                )
            }
            .padding(28)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 760, minHeight: 650)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: store.shuffleAll) {
                    Label("Shuffle All", systemImage: "arrow.triangle.2.circlepath")
                }
                .keyboardShortcut("r", modifiers: .command)
                .help("Shuffle All (⌘R)")
                .accessibilityLabel("Shuffle all GRE words")
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.reloadFromPersistence()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 31, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("GRE Glance")
                    .font(.largeTitle.weight(.semibold))
                Text("See more words. Remember naturally.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView(store: AppWordStore())
        .frame(width: 900, height: 820)
}
