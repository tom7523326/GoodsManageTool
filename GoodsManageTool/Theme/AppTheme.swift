import SwiftUI

enum AppTheme {
    static let accent = Color(red: 1.0, green: 0.42, blue: 0.21)
    static let accentDark = Color(red: 0.86, green: 0.28, blue: 0.12)
    static let success = Color(red: 0.13, green: 0.72, blue: 0.45)
    static let warning = Color(red: 0.98, green: 0.62, blue: 0.04)
    static let danger = Color(red: 0.93, green: 0.26, blue: 0.21)
    static let surface = Color(.systemBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let pageBackground = Color(red: 0.97, green: 0.97, blue: 0.98)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.48, blue: 0.26),
            Color(red: 1.0, green: 0.64, blue: 0.22)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let showcaseGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.95, blue: 0.92),
            Color(red: 1.0, green: 0.98, blue: 0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}
