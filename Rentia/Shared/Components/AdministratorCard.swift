import SwiftUI

struct AdministratorCard: View {
    let administrator: Administrator

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            initialsAvatar

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(administrator.name)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(administrator.phone)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Text(administrator.email)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textLight)
        }
        .padding(AppSpacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(
            color: AppTheme.Shadows.card,
            radius: AppTheme.Shadows.cardRadius,
            x: AppTheme.Shadows.cardX,
            y: AppTheme.Shadows.cardY
        )
    }

    private var initialsAvatar: some View {
        Text(administrator.initials)
            .font(AppTypography.headline)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(AppTheme.Colors.secondary)
            .clipShape(Circle())
    }
}
