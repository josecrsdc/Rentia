import SwiftUI

struct SettingsView: View {
    @Environment(\.container) private var container
    @State private var viewModel: ProfileViewModel?
    @AppStorage("defaultCurrency") private var defaultCurrency = "EUR"
    #if DEBUG
    @State private var seedingState: SeedingState = .idle
    #endif

    private let availableCurrencies = ["EUR", "USD", "MXN", "COP"]

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    profileHeader
                    accountSection
                    preferencesSection
                    #if DEBUG
                    debugSection
                    #endif
                    dangerZoneSection
                }
                .padding(AppSpacing.medium)
            }
        }
        .navigationTitle(String(localized: "Ajustes"))
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel(
                    authService: container.authService
                )
            }
            viewModel?.loadProfile()
        }
        .confirmationDialog(
            String(localized: "Cerrar Sesion"),
            isPresented: Binding(
                get: { viewModel?.showSignOutConfirmation ?? false },
                set: { viewModel?.showSignOutConfirmation = $0 }
            ),
            titleVisibility: .visible
        ) {
            Button(
                String(localized: "Cerrar Sesion"),
                role: .destructive
            ) {
                viewModel?.signOut()
            }
        } message: {
            Text(String(localized: "Estas seguro que deseas cerrar sesion?"))
        }
        .confirmationDialog(
            String(localized: "Eliminar Cuenta"),
            isPresented: Binding(
                get: { viewModel?.showDeleteConfirmation ?? false },
                set: { viewModel?.showDeleteConfirmation = $0 }
            ),
            titleVisibility: .visible
        ) {
            Button(
                String(localized: "Eliminar Cuenta"),
                role: .destructive
            ) {
                viewModel?.deleteAccount()
            }
        } message: {
            Text(
                String(
                    localized: "Esta accion es irreversible. Se eliminaran todos tus datos."
                )
            )
        }
        .alert(
            String(localized: "Error"),
            isPresented: Binding(
                get: { viewModel?.showError ?? false },
                set: { viewModel?.showError = $0 }
            )
        ) {
            Button(String(localized: "Aceptar"), role: .cancel) {}
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: AppSpacing.medium) {
            if let photoURL = viewModel?.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }

            VStack(spacing: AppSpacing.extraSmall) {
                Text(viewModel?.displayName ?? "")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(viewModel?.email ?? "")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .foregroundStyle(AppTheme.Colors.primary.opacity(0.3))
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Cuenta"))
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            profileRow(
                icon: "person",
                title: viewModel?.displayName ?? "",
                subtitle: String(localized: "Nombre")
            )

            profileRow(
                icon: "envelope",
                title: viewModel?.email ?? "",
                subtitle: String(localized: "Email")
            )

            profileRow(
                icon: "shield.checkered",
                title: viewModel?.userProfile?.authProvider
                    .capitalized ?? "N/A",
                subtitle: String(localized: "Proveedor de autenticacion")
            )
        }
        .cardStyle()
    }

    private func profileRow(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(width: 32, height: 32)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.small
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Preferencias"))
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

                Text(String(localized: "Moneda por defecto"))
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
        .cardStyle()
    }

    // MARK: - Debug

    #if DEBUG
    private enum SeedingState {
        case idle
        case loading
        case done
    }

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Debug")
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
                    Text(String(localized: "Cargar datos de prueba"))
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
                    Text(String(localized: "Eliminar todos los datos"))
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
    #endif

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Button {
                viewModel?.showSignOutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text(String(localized: "Cerrar Sesion"))
                        .font(AppTypography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.Colors.cardBackground)
                .foregroundStyle(AppTheme.Colors.error)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.medium
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.medium
                    )
                    .stroke(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                )
            }

            Button {
                viewModel?.showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text(String(localized: "Eliminar Cuenta"))
                        .font(AppTypography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.Colors.error.opacity(0.1))
                .foregroundStyle(AppTheme.Colors.error)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.medium
                    )
                )
            }
        }
    }
}
