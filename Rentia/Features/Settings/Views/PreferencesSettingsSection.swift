import SwiftUI

struct PreferencesSettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("settings.preferences.title")
                .sectionTitle()

            DefaultCurrencyRow()
            AppearanceModeRow()
            FontScaleRow()
        }
        .cardStyle()
    }
}

private struct DefaultCurrencyRow: View {
    @AppStorage("defaultCurrency")
    private var defaultCurrency = "EUR"

    private let availableCurrencies = ["EUR", "USD", "MXN", "COP"]

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            SettingsSectionIcon(systemName: "dollarsign.circle")

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
    }
}

private struct AppearanceModeRow: View {
    @AppStorage("appearanceMode")
    private var appearanceMode = "system"

    private let appearanceOptions: [(String, LocalizedStringKey)] = [
        ("system", "settings.preferences.appearance.system"),
        ("light", "settings.preferences.appearance.light"),
        ("dark", "settings.preferences.appearance.dark"),
    ]

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            SettingsSectionIcon(systemName: "circle.lefthalf.filled")

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
}

private struct FontScaleRow: View {
    @AppStorage("fontScale")
    private var fontScale: Double = 1.0

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            SettingsSectionIcon(systemName: "textformat.size")

            Text("settings.preferences.text_size")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            Picker("", selection: $fontScale) {
                Text("settings.preferences.text_size.small").tag(0.85)
                Text("settings.preferences.text_size.medium").font(.callout).tag(1.0)
                Text("settings.preferences.text_size.large").font(.headline).tag(1.15)
                Text("settings.preferences.text_size.extra_large").font(.title3).tag(1.3)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)
            .tint(AppTheme.Colors.primary)
        }
    }
}
