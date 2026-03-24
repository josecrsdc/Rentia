import SwiftUI

struct SettingsSectionIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .foregroundStyle(AppTheme.Colors.primary)
            .frame(width: 32, height: 32)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }
}
