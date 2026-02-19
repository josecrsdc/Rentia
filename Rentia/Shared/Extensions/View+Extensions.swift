import SwiftUI

extension View {
    func cardStyle() -> some View {
        padding(AppSpacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
            )
            .shadow(
                color: AppTheme.Shadows.card,
                radius: AppTheme.Shadows.cardRadius,
                x: AppTheme.Shadows.cardX,
                y: AppTheme.Shadows.cardY
            )
    }

    func sectionTitle() -> some View {
        font(AppTypography.title3)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
