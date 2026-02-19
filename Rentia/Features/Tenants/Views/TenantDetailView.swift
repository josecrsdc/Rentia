import SwiftUI

struct TenantDetailView: View {
    let tenantId: String
    @State private var tenant: Tenant?
    @State private var properties: [Property] = []
    @State private var payments: [Payment] = []
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @AppStorage("defaultCurrency") private var defaultCurrency = "EUR"
    @Environment(\.dismiss) private var dismiss

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
        .alert(
            String(localized: "Eliminar Inquilino"),
            isPresented: $showDeleteConfirmation
        ) {
            Button(String(localized: "Cancelar"), role: .cancel) {}
            Button(String(localized: "Eliminar"), role: .destructive) {
                deleteTenant()
            }
        } message: {
            Text(
                String(localized: "Esta accion no se puede deshacer. Se eliminara el inquilino permanentemente.")
            )
        }
    }

    private func tenantContent(_ tenant: Tenant) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                tenantHeader(tenant)
                contactSection(tenant)
                if !properties.isEmpty {
                    propertiesSection
                }
                leaseSection(tenant)
                paymentsSection
                deleteButton
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

    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Propiedades"))
                .font(AppTypography.title3)

            ForEach(properties) { property in
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: property.type.icon)
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(property.name)
                            .font(AppTypography.body)

                        Text(property.address)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(property.status.displayName)
                        .font(AppTypography.caption2)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.extraSmall)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .clipShape(Capsule())
                }
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
                    .formatted(.currency(code: defaultCurrency))
            )

            detailRow(
                icon: "shield",
                label: String(localized: "Deposito"),
                value: tenant.depositAmount
                    .formatted(.currency(code: defaultCurrency))
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

    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Pagos"))
                .font(AppTypography.title3)

            if payments.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .foregroundStyle(AppTheme.Colors.textLight)

                    Text(String(localized: "Sin pagos registrados"))
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            } else {
                ForEach(payments) { payment in
                    NavigationLink(
                        value: PaymentDestination.detail(payment.id ?? "")
                    ) {
                        PaymentCard(payment: payment)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text(String(localized: "Eliminar Inquilino"))
            }
            .font(AppTypography.body)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.medium)
            .background(AppTheme.Colors.error.opacity(0.1))
            .foregroundStyle(AppTheme.Colors.error)
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
            )
        }
    }

    private func deleteTenant() {
        Task {
            do {
                try await firestoreService.delete(
                    id: tenantId,
                    from: "tenants"
                )
                dismiss()
            } catch {
                // Handle error
            }
        }
    }

    private func loadTenant() {
        Task {
            do {
                let loadedTenant: Tenant = try await firestoreService.read(
                    id: tenantId,
                    from: "tenants"
                )
                tenant = loadedTenant
                await loadProperties(for: loadedTenant.propertyIds)
            } catch {
                // Handle error
            }

            payments = (
                try? await firestoreService.readAll(
                    from: "payments",
                    whereField: "tenantId",
                    isEqualTo: tenantId
                )
            ) ?? []

            isLoading = false
        }
    }

    private func loadProperties(for propertyIds: [String]) async {
        var loaded: [Property] = []
        for propertyId in propertyIds {
            if let property: Property = try? await firestoreService.read(
                id: propertyId,
                from: "properties"
            ) {
                loaded.append(property)
            }
        }
        properties = loaded
    }
}
