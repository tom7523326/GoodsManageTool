import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 1.0, green: 0.42, blue: 0.21)

    /// Emphasis text on cards and chips — brighter in dark mode for contrast.
    static let accentDark = dynamicColor(
        light: UIColor(red: 0.86, green: 0.28, blue: 0.12, alpha: 1),
        dark: UIColor(red: 1.0, green: 0.62, blue: 0.38, alpha: 1)
    )

    static let success = dynamicColor(
        light: UIColor(red: 0.13, green: 0.72, blue: 0.45, alpha: 1),
        dark: UIColor(red: 0.35, green: 0.85, blue: 0.58, alpha: 1)
    )

    static let warning = dynamicColor(
        light: UIColor(red: 0.98, green: 0.62, blue: 0.04, alpha: 1),
        dark: UIColor(red: 1.0, green: 0.75, blue: 0.28, alpha: 1)
    )

    static let danger = dynamicColor(
        light: UIColor(red: 0.93, green: 0.26, blue: 0.21, alpha: 1),
        dark: UIColor(red: 1.0, green: 0.45, blue: 0.40, alpha: 1)
    )

    static let surface = Color(.systemBackground)
    static let card = Color(.secondarySystemGroupedBackground)

    static let pageBackground = dynamicColor(
        light: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1),
        dark: UIColor.systemGroupedBackground
    )

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.48, blue: 0.26),
            Color(red: 1.0, green: 0.64, blue: 0.22)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let showcaseGradientLight = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.95, blue: 0.92),
            Color(red: 1.0, green: 0.98, blue: 0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let showcaseGradientDark = LinearGradient(
        colors: [
            Color(.systemBackground),
            Color(.secondarySystemBackground)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct ShowcasePageBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                AppTheme.showcaseGradientDark
            } else {
                AppTheme.showcaseGradientLight
            }
        }
    }
}

struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06),
                radius: colorScheme == .dark ? 8 : 12,
                x: 0,
                y: colorScheme == .dark ? 2 : 4
            )
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}
