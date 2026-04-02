import SwiftUI

struct PaymentCard: View {
    let payment: Payment
    var propertyName: String? = nil
    @AppStorage("defaultCurrency")
    private var defaultCurrency = "EUR"

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: payment.status.icon)
                .font(AppTypography.title3)
                .foregroundStyle(statusColor)
                .frame(width: 44, height: 44)
                .background(statusColor.opacity(0.1))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.small
                    )
                )

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(payment.amount.formatted(.currency(code: defaultCurrency)))
                    .font(AppTypography.moneySmall)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                if let name = propertyName, !name.isEmpty {
                    Text(name)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Text(payment.date.shortFormatted)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [payment.amount.formatted(.currency(code: defaultCurrency))]
        if let name = propertyName, !name.isEmpty {
            parts.append(name)
        }
        parts.append(payment.date.shortFormatted)
        parts.append(String(localized: "payments.status.\(payment.status.rawValue)"))
        return parts.joined(separator: ", ")
    }

    private var statusPill: some View {
        Text(payment.status.localizedName)
            .font(AppTypography.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.extraSmall)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch payment.status {
        case .paid: AppTheme.Colors.success
        case .pending: AppTheme.Colors.warning
        case .overdue: AppTheme.Colors.error
        case .partial: AppTheme.Colors.accent
        case .cancelled: AppTheme.Colors.textLight
        }
    }
}
