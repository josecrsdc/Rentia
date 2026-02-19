import SwiftUI

enum AppTheme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color("Primary")
        static let secondary = Color("Secondary")
        static let accent = Color("Accent")
        static let background = Color("Background")
        static let cardBackground = Color("CardBackground")
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let error = Color("Error")

        static let textPrimary = Color("Primary")
        static let textSecondary = Color.gray
        static let textLight = Color.gray.opacity(0.6)
    }

    // MARK: - Gradients
    enum Gradients {
        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.primary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accent = LinearGradient(
            colors: [Colors.secondary, Colors.secondary.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let card = LinearGradient(
            colors: [Colors.cardBackground, Colors.cardBackground.opacity(0.95)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Shadows
    enum Shadows {
        static let card = Color.black.opacity(0.08)
        static let cardRadius: CGFloat = 8
        static let cardX: CGFloat = 0
        static let cardY: CGFloat = 4

        static let button = Color.black.opacity(0.12)
        static let buttonRadius: CGFloat = 12
        static let buttonX: CGFloat = 0
        static let buttonY: CGFloat = 6
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let pill: CGFloat = 50
    }
}
