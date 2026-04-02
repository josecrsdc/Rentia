import SwiftUI

#if DEBUG
struct DebugView: View {
    @State private var seedingState: SeedingState = .idle
    private let dataSeeder = DataSeeder()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.large) {
                debugSection
                Spacer()
            }
            .padding(AppSpacing.medium)
        }
        .navigationTitle("common.debug")
    }

    private enum SeedingState: Equatable {
        case idle
        case loading(DebugAction)
    }

    private enum DebugAction: Equatable {
        case loadAll
        case createProperty
        case createTenant
        case createAdministrator
        case deleteAll
    }

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("common.debug")
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            debugButton(
                title: "settings.debug.load_seed_data",
                systemImage: "tray.and.arrow.down",
                color: AppTheme.Colors.primary,
                action: .loadAll
            ) {
                await dataSeeder.seed()
            }

            debugButton(
                title: "Crear propiedad de prueba",
                systemImage: "building.2",
                color: AppTheme.Colors.secondary,
                action: .createProperty
            ) {
                await dataSeeder.seedProperty()
            }

            debugButton(
                title: "Crear inquilino de prueba",
                systemImage: "person",
                color: AppTheme.Colors.accent,
                action: .createTenant
            ) {
                await dataSeeder.seedTenant()
            }

            debugButton(
                title: "Crear administrador de prueba",
                systemImage: "person.badge.shield.checkmark",
                color: AppTheme.Colors.success,
                action: .createAdministrator
            ) {
                await dataSeeder.seedAdministrator()
            }

            debugButton(
                title: "settings.debug.delete_all_data",
                systemImage: "trash",
                color: AppTheme.Colors.warning,
                action: .deleteAll
            ) {
                await dataSeeder.deleteAll()
            }
        }
        .cardStyle()
    }

    private func debugButton(
        title: LocalizedStringKey,
        systemImage: String,
        color: Color,
        action: DebugAction,
        task: @escaping () async -> Void
    ) -> some View {
        Button {
            seedingState = .loading(action)
            Task {
                await task()
                await MainActor.run {
                    seedingState = .idle
                }
            }
        } label: {
            HStack {
                if seedingState == .loading(action) {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .font(AppTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.CornerRadius.medium
                )
            )
        }
        .disabled(isLoading)
    }

    private var isLoading: Bool {
        if case .loading = seedingState {
            true
        } else {
            false
        }
    }
}
#endif
