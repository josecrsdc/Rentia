import SwiftUI

#if DEBUG
struct DebugView: View {
    @State private var seedingState: SeedingState = .idle

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

    private enum SeedingState {
        case idle
        case loading
        case done
    }

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("common.debug")
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Button {
                seedingState = .loading
                Task {
                    await DataSeeder().seed()
                    seedingState = .idle
                }
            } label: {
                HStack {
                    if seedingState == .loading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "tray.and.arrow.down")
                    }
                    Text("settings.cargar_datos_de_prueba")
                        .font(AppTypography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .foregroundStyle(AppTheme.Colors.primary)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.medium
                    )
                )
            }
            .disabled(seedingState == .loading)

            Button {
                seedingState = .loading
                Task {
                    await DataSeeder().deleteAll()
                    seedingState = .idle
                }
            } label: {
                HStack {
                    if seedingState == .loading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "trash")
                    }
                    Text("settings.eliminar_todos_los_datos")
                        .font(AppTypography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.Colors.warning.opacity(0.1))
                .foregroundStyle(AppTheme.Colors.warning)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.medium
                    )
                )
            }
            .disabled(seedingState == .loading)
        }
        .cardStyle()
    }
}
#endif
