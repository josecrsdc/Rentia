import SwiftUI

struct TenantDetailView: View {
    let tenantId: String
    @State private var tenant: Tenant?
    @State private var isLoading = true

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let tenant {
                tenantContent(tenant)
            }
        }
        .navigationTitle(tenant?.fullName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(
                    value: TenantDestination.form(tenantId)
                ) {
                    Text(String(localized: "Editar"))
                }
            }
        }
        .onAppear { loadTenant() }
    }

    private func tenantContent(_ tenant: Tenant) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                tenantHeader(tenant)
                contactSection(tenant)
                leaseSection(tenant)
            }
            .padding(AppSpacing.medium)
        }
    }

    private func tenantHeader(_ tenant: Tenant) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Text(initials(for: tenant))
                .font(AppTypography.title2)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(AppTheme.Colors.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(tenant.fullName)
                    .font(AppTypography.title2)

                Text(tenant.status.displayName)
                    .font(AppTypography.caption)
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.extraSmall)
                    .background(
                        tenant.status == .active
                            ? AppTheme.Colors.success.opacity(0.15)
                            : AppTheme.Colors.textSecondary.opacity(0.15)
                    )
                    .foregroundStyle(
                        tenant.status == .active
                            ? AppTheme.Colors.success
                            : AppTheme.Colors.textSecondary
                    )
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func contactSection(_ tenant: Tenant) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Contacto"))
                .font(AppTypography.title3)

            detailRow(
                icon: "envelope",
                label: String(localized: "Email"),
                value: tenant.email
            )

            detailRow(
                icon: "phone",
                label: String(localized: "Telefono"),
                value: tenant.phone
            )

            if let idNumber = tenant.idNumber, !idNumber.isEmpty {
                detailRow(
                    icon: "person.text.rectangle",
                    label: String(localized: "Identificacion"),
                    value: idNumber
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func leaseSection(_ tenant: Tenant) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Contrato"))
                .font(AppTypography.title3)

            if let start = tenant.leaseStartDate {
                detailRow(
                    icon: "calendar",
                    label: String(localized: "Inicio"),
                    value: start.shortFormatted
                )
            }

            if let end = tenant.leaseEndDate {
                detailRow(
                    icon: "calendar.badge.clock",
                    label: String(localized: "Fin"),
                    value: end.shortFormatted
                )
            }

            detailRow(
                icon: "dollarsign.circle",
                label: String(localized: "Renta"),
                value: tenant.monthlyRent
                    .formatted(.currency(code: "USD"))
            )

            detailRow(
                icon: "shield",
                label: String(localized: "Deposito"),
                value: tenant.depositAmount
                    .formatted(.currency(code: "USD"))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func detailRow(
        icon: String,
        label: String,
        value: String
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(AppTypography.headline)
        }
    }

    private func initials(for tenant: Tenant) -> String {
        let first = tenant.firstName.prefix(1).uppercased()
        let last = tenant.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    private func loadTenant() {
        Task {
            do {
                tenant = try await firestoreService.read(
                    id: tenantId,
                    from: "tenants"
                )
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}
