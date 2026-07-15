import SwiftUI

struct InstructionsView: View {
    private let steps = [
        "在桌面空白处右键 / Right-click the desktop",
        "选择“编辑小组件” / Choose Edit Widgets",
        "搜索“GRE Glance” / Search for GRE Glance",
        "选择大号尺寸并添加 / Add the large size"
    ]

    var body: some View {
        GroupBox("添加到桌面") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .background(.quaternary, in: Circle())
                        Text(step)
                            .font(.callout)
                    }
                }
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
