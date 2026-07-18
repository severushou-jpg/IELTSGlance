import SwiftUI

struct SettingsView: View {
    let store: AppWordStore

    var body: some View {
        Form {
            Section("Widget 显示") {
                Picker("默认字号", selection: Binding(
                    get: { store.defaultTextSize },
                    set: store.setDefaultTextSize
                )) {
                    ForEach(WidgetTextSize.appSelectableCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)

                Picker("同义词数量", selection: Binding(
                    get: { store.synonymLimit },
                    set: store.setSynonymLimit
                )) {
                    ForEach(1...3, id: \.self) { count in
                        Text("\(count) 个").tag(count)
                    }
                }
                .pickerStyle(.segmented)

                Text("桌面上的每个 Widget 还可单独选择字号；“跟随 App 设置”会使用这里的默认值。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("当前范围") {
                LabeledContent("已选词包", value: "\(store.selectedPackIDs.count) / \(store.packs.count)")
                LabeledContent("随机池", value: "\(store.selectedWordCount) 个词")
                Text("词包选择请在主窗口中调整，App 与 Widget 会共享同一范围。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480, height: 330)
    }
}
