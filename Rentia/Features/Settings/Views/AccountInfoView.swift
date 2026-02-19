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
        .navigationTitle("account.title")
        .confirmationDialog("account.delete",
            isPresented: Binding(
                get: { viewModel?.showDeleteConfirmation ?? false },
                set: { viewModel?.showDeleteConfirmation = $0 }
            ),
            titleVisibility: .visible
        ) {
            Button(
                "account.delete",
                role: .destructive
            ) {
                viewModel?.deleteAccount()
            }
        } message: {
            Text("account.delete.confirmation.message")
        }
        .alert("common.error",
            isPresented: Binding(
                get: { viewModel?.showError ?? false },
                set: { viewModel?.showError = $0 }
            )
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("account.title")
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            profileRow(
                icon: "person",
                title: viewModel?.displayName ?? "",
                subtitle: "tenants.first_name"
            )

            profileRow(
                icon: "envelope",
                title: viewModel?.email ?? "",
                subtitle: "tenants.email"
            )

            profileRow(
                icon: "shield.checkered",
                title: viewModel?.userProfile?.authProvider
                    .capitalized ?? "N/A",
                subtitle: "settings.proveedor_de_autenticacion"
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
                Text("account.delete")
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
