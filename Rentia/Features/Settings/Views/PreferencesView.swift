import SwiftUI

struct PreferencesView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    PreferencesSettingsSection()
                    NotificationSettingsSection()
                }
                .padding(AppSpacing.medium)
            }
        }
        .navigationTitle("settings.preferences.title")
    }
}
