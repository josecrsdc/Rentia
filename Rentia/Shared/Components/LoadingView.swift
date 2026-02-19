import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.large) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.Colors.primary)

                ProgressView()
                    .tint(AppTheme.Colors.primary)
            }
        }
    }
}
