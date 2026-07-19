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

                Text("App 预览使用这里的设置；桌面 Widget 可在“编辑小组件”中独立选择字号和词包。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("当前范围") {
                LabeledContent("已选词包", value: "\(store.selectedPackIDs.count) / \(store.packs.count)")
                LabeledContent("随机池", value: "\(store.selectedWordCount) 个词")
                Text("这里显示 App 预览的范围。Widget 的随机范围请在桌面上右键小组件并选择“编辑小组件”。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480, height: 330)
    }
}
