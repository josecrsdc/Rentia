import SwiftUI

struct AccountInfoView: View {
    let viewModel: ProfileViewModel?

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.large) {
                accountSection
                Spacer()
                dangerZoneSection
            }
            .padding(AppSpacing.medium)
        }
        .navigationTitle(String(localized: "Cuenta"))
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

    private var dangerZoneSection: some View {
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
