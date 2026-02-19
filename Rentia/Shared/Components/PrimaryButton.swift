import SwiftUI

struct PrimaryButton: View {
    let title: LocalizedStringKey
    let isLoading: Bool
    let action: () -> Void

    init(
        title: LocalizedStringKey,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(AppTypography.headline)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.Gradients.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .shadow(
                color: AppTheme.Shadows.button,
                radius: AppTheme.Shadows.buttonRadius,
                x: AppTheme.Shadows.buttonX,
                y: AppTheme.Shadows.buttonY
            )
        }
        .disabled(isLoading)
    }
}
