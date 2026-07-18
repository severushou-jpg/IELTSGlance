import SwiftUI

struct AboutView: View {
    let totalWordCount: Int
    let stateModeDescription: String
    let usesSharedState: Bool
    let usesFallbackData: Bool

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            GroupBox("数据信息") {
                infoRows
                    .padding(.top, 5)
            }

            GroupBox("About / Credits") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GRE Glance \(version)")
                        .font(.callout.weight(.semibold))
                    Text("代码：MIT License")
                    Text("词库：ECDICT MIT + Open English WordNet CC BY 4.0")
                    if let repositoryURL = URL(string: "https://github.com/severushou-jpg/GRE-Glance") {
                        Link("GitHub：severushou-jpg/GRE-Glance", destination: repositoryURL)
                    }
                    Text("独立学习工具，与 ETS 无隶属或背书关系。")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 5)
            }
        }
    }

    private var infoRows: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
            row("词库", "\(totalWordCount) 个词")
            row("运行模式", stateModeDescription)
            row("共享状态", usesSharedState ? "是" : "否（App 与 Widget 各自独立）")
            row("数据", usesFallbackData ? "内置安全示例" : "本地 JSON")
            row("隐私", "完全离线，仅保存在本机")
        }
        .font(.caption)
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .lineLimit(1)
        }
    }
}
