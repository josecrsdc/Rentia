import SwiftUI

struct StatCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(AppTypography.title3)
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(AppTypography.moneyMedium)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(
            color: AppTheme.Shadows.card,
            radius: AppTheme.Shadows.cardRadius,
            x: AppTheme.Shadows.cardX,
            y: AppTheme.Shadows.cardY
        )
    }
}
