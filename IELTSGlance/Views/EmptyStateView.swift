import SwiftUI

struct EmptyStateView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "无法显示词库",
            systemImage: "text.book.closed",
            description: Text(message)
        )
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
