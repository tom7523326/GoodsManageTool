import SwiftUI

struct SampleBadge: View {
    var body: some View {
        Text("示例")
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(AppTheme.warning.opacity(0.16), in: Capsule())
            .foregroundStyle(AppTheme.warning)
    }
}
