import SwiftUI

struct PreferencesView: View {
    @AppStorage("defaultCurrency") private var defaultCurrency = "EUR"
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    private let availableCurrencies = ["EUR", "USD", "MXN", "COP"]
    private let appearanceOptions = [
        ("system", "settings.preferences.appearance.system"),
        ("light", "settings.preferences.appearance.light"),
        ("dark", "settings.preferences.appearance.dark"),
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.large) {
                preferencesSection
                Spacer()
            }
            .padding(AppSpacing.medium)
        }
        .navigationTitle("settings.preferences.title")
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("settings.preferences.title")
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.CornerRadius.small
                        )
                    )

                Text("settings.preferences.default_currency")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Picker("", selection: $defaultCurrency) {
                    ForEach(availableCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .tint(AppTheme.Colors.primary)
            }

            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.CornerRadius.small
                        )
                    )

                Text("settings.preferences.appearance")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Picker("", selection: $appearanceMode) {
                    ForEach(appearanceOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }
                .tint(AppTheme.Colors.primary)
            }
        }
        .cardStyle()
    }
}
