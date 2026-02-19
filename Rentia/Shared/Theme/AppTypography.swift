import SwiftUI

enum AppTypography {
    // MARK: - Headlines
    static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
    static let title = Font.system(.title, design: .default, weight: .bold)
    static let title2 = Font.system(.title2, design: .default, weight: .semibold)
    static let title3 = Font.system(.title3, design: .default, weight: .semibold)

    // MARK: - Body
    static let headline = Font.system(.headline, design: .default, weight: .semibold)
    static let body = Font.system(.body, design: .default, weight: .regular)
    static let callout = Font.system(.callout, design: .default, weight: .regular)
    static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)

    // MARK: - Small
    static let footnote = Font.system(.footnote, design: .default, weight: .regular)
    static let caption = Font.system(.caption, design: .default, weight: .light)
    static let caption2 = Font.system(.caption2, design: .default, weight: .light)

    // MARK: - Monospaced (for financial data)
    static let moneyLarge = Font.system(.title, design: .monospaced, weight: .bold)
    static let moneyMedium = Font.system(.title3, design: .monospaced, weight: .semibold)
    static let moneySmall = Font.system(.body, design: .monospaced, weight: .medium)
}
