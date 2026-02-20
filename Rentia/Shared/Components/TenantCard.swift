import SwiftUI

struct TenantCard: View {
    let tenant: Tenant

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            initialsAvatar

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(tenant.fullName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(tenant.email)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            statusPill
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
        Text(initials)
            .font(AppTypography.headline)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(AppTheme.Colors.primary)
            .clipShape(Circle())
    }

    private var initials: String {
        let first = tenant.firstName.prefix(1).uppercased()
        let last = tenant.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    private var statusPill: some View {
        Text(tenant.status.localizedName)
            .font(AppTypography.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.extraSmall)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch tenant.status {
        case .active: AppTheme.Colors.success
        case .inactive: AppTheme.Colors.textSecondary
        }
    }
}
