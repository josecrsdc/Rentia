import FirebaseFirestore
import SwiftUI

struct PropertyDetailView: View {
    let propertyId: String
    @State private var property: Property?
    @State private var tenants: [Tenant] = []
    @State private var payments: [Payment] = []
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let property {
                propertyContent(property)
            }
        }
        .navigationTitle(property?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(
                    value: PropertyDestination.form(propertyId)
                ) {
                    Text(String(localized: "Editar"))
                }
            }
        }
        .onAppear { loadProperty() }
        .alert(
            String(localized: "Eliminar Propiedad"),
            isPresented: $showDeleteConfirmation
        ) {
            Button(String(localized: "Cancelar"), role: .cancel) {}
            Button(String(localized: "Eliminar"), role: .destructive) {
                deleteProperty()
            }
        } message: {
            Text(
                String(localized: "Esta accion no se puede deshacer. Se eliminara la propiedad permanentemente.")
            )
        }
    }

    private func propertyContent(_ property: Property) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                propertyHeader(property)
                propertyDetails(property)
                tenantsSection
                paymentsSection
                propertyStats(property)
                deleteButton
            }
            .padding(AppSpacing.medium)
        }
    }

    private func propertyHeader(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                propertyIcon(property)

                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text(property.name)
                        .font(AppTypography.title2)

                    Text(property.address)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Text(
                property.monthlyRent.formatted(
                    .currency(code: property.currency)
                )
            )
            .font(AppTypography.moneyLarge)
            .foregroundStyle(AppTheme.Colors.primary)
            .padding(.top, AppSpacing.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func propertyIcon(_ property: Property) -> some View {
        Image(systemName: property.type.icon)
            .font(.title2)
            .foregroundStyle(AppTheme.Colors.primary)
            .frame(width: 56, height: 56)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.CornerRadius.medium
                )
            )
    }

    private func propertyDetails(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Detalles"))
                .font(AppTypography.title3)

            if let description = property.description, !description.isEmpty {
                Text(description)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            detailRow(
                icon: "tag",
                label: String(localized: "Tipo"),
                value: property.type.displayName
            )

            detailRow(
                icon: "circle.fill",
                label: String(localized: "Estado"),
                value: property.status.displayName
            )

            if let area = property.area {
                detailRow(
                    icon: "square.dashed",
                    label: String(localized: "Area"),
                    value: "\(Int(area)) m²"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Tenants Section

    private var tenantsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Inquilinos"))
                .font(AppTypography.title3)

            if tenants.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "person.2.slash")
                        .foregroundStyle(AppTheme.Colors.textLight)

                    Text(String(localized: "Sin inquilinos asignados"))
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            } else {
                ForEach(tenants) { tenant in
                    NavigationLink(
                        value: TenantDestination.detail(tenant.id ?? "")
                    ) {
                        tenantRow(tenant)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func tenantRow(_ tenant: Tenant) -> some View {
        HStack(spacing: AppSpacing.small) {
            Text(initials(for: tenant))
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(AppTheme.Colors.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(tenant.fullName)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(tenant.email)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(tenant.status.displayName)
                .font(AppTypography.caption2)
                .fontWeight(.medium)
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

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textLight)
        }
    }

    // MARK: - Payments Section

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

    private func propertyStats(_ property: Property) -> some View {
        HStack(spacing: AppSpacing.medium) {
            StatCard(
                title: String(localized: "Habitaciones"),
                value: "\(property.rooms)",
                icon: "bed.double",
                color: AppTheme.Colors.primary
            )

            StatCard(
                title: String(localized: "Banos"),
                value: "\(property.bathrooms)",
                icon: "shower",
                color: AppTheme.Colors.secondary
            )
        }
    }

    private func initials(for tenant: Tenant) -> String {
        let first = tenant.firstName.prefix(1).uppercased()
        let last = tenant.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text(String(localized: "Eliminar Propiedad"))
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

    private func deleteProperty() {
        Task {
            do {
                try await firestoreService.delete(
                    id: propertyId,
                    from: "properties"
                )
                dismiss()
            } catch {
                // Handle error
            }
        }
    }

    private func loadProperty() {
        Task {
            do {
                async let propertyResult: Property = firestoreService.read(
                    id: propertyId,
                    from: "properties"
                )
                async let tenantsResult: [Tenant] = firestoreService.readAll(
                    from: "tenants",
                    whereField: "propertyIds",
                    arrayContains: propertyId
                )
                async let paymentsResult: [Payment] = firestoreService.readAll(
                    from: "payments",
                    whereField: "propertyId",
                    isEqualTo: propertyId
                )
                property = try await propertyResult
                tenants = try await tenantsResult
                payments = try await paymentsResult
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}
