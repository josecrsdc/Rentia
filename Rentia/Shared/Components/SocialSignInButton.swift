import SwiftUI

struct SocialSignInButton: View {
    let title: String
    let icon: String
    let isSystemImage: Bool
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void

    init(
        title: String,
        icon: String,
        isSystemImage: Bool = true,
        backgroundColor: Color = AppTheme.Colors.cardBackground,
        foregroundColor: Color = AppTheme.Colors.textPrimary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSystemImage = isSystemImage
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                if isSystemImage {
                    Image(systemName: icon)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                } else {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }

                Text(title)
                    .font(AppTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
