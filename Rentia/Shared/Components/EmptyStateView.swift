import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.textLight)

            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(message)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.extraLarge)
                        .padding(.vertical, AppSpacing.medium)
                        .background(AppTheme.Colors.primary)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppTheme.CornerRadius.medium
                            )
                        )
                }
            }
        }
        .padding(AppSpacing.xxLarge)
        .frame(maxWidth: .infinity)
    }
}
