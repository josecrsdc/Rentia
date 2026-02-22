import SwiftUI

struct PropertyCard: View {
    let property: Property
    var isRented: Bool = false

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

                    Text(property.address.formattedShort)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                statusPill
            }

            HStack {
                if property.type.supportsRoomsBathrooms {
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
                } else if let area = property.area {
                    Label(
                        "\(Int(area)) m²",
                        systemImage: "square.dashed"
                    )
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()
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
        Text(statusLabel)
            .font(AppTypography.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.extraSmall)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusLabel: LocalizedStringKey {
        if isRented {
            return "properties.status.rented"
        }
        return property.status.localizedName
    }

    private var statusColor: Color {
        if isRented {
            return AppTheme.Colors.primary
        }
        switch property.status {
        case .available: return AppTheme.Colors.success
        case .maintenance: return AppTheme.Colors.warning
        }
    }
}
