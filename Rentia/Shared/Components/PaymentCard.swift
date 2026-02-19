import SwiftUI

struct PaymentCard: View {
    let payment: Payment

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
                Text(payment.amount.formatted(.currency(code: "USD")))
                    .font(AppTypography.moneySmall)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

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
    }

    private var statusPill: some View {
        Text(payment.status.displayName)
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
        }
    }
}
