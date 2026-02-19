import SwiftUI

struct PropertyCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: property.type.icon)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.CornerRadius.small
                        )
                    )

                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text(property.name)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text(property.address)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                statusPill
            }

            HStack {
                Label(
                    "\(property.rooms)",
                    systemImage: "bed.double"
                )
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

                Label(
                    "\(property.bathrooms)",
                    systemImage: "shower"
                )
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

                Spacer()

                Text(
                    property.monthlyRent.formatted(
                        .currency(code: property.currency)
                    )
                )
                .font(AppTypography.moneySmall)
                .foregroundStyle(AppTheme.Colors.primary)
            }
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

    private var statusPill: some View {
        Text(property.status.displayName)
            .font(AppTypography.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.extraSmall)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch property.status {
        case .available: AppTheme.Colors.success
        case .rented: AppTheme.Colors.primary
        case .maintenance: AppTheme.Colors.warning
        }
    }
}
