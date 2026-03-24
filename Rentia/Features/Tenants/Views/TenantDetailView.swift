import FirebaseAuth
import SwiftUI

struct TenantDetailView: View {
    let tenantId: String
    @State private var tenant: Tenant?
    @State private var properties: [Property] = []
    @State private var leases: [Lease] = []
    @State private var payments: [Payment] = []
    @State private var isLoading = true
    @Environment(\.dismiss)
    private var dismiss

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
                    Text("common.edit")
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
                if !leases.isEmpty {
                    leasesSection
                }
                if !properties.isEmpty {
                    propertiesSection
                }
                paymentsSection
                DocumentListView(entityId: tenantId, entityType: .tenant)
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

                Text(tenant.status.localizedName)
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
            Text("tenants.contact")
                .font(AppTypography.title3)

            tappableRow(
                icon: "envelope",
                label: "tenants.email",
                value: tenant.email,
                url: "mailto:\(tenant.email)"
            )

            tappableRow(
                icon: "phone",
                label: "tenants.phone",
                value: tenant.phone,
                url: "tel:\(tenant.phone.replacingOccurrences(of: " ", with: ""))"
            )

            if let idNumber = tenant.idNumber, !idNumber.isEmpty {
                detailRow(
                    icon: "person.text.rectangle",
                    label: "tenants.identification",
                    value: idNumber
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Leases Section

    private var leasesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("leases.tenant_contracts")
                .font(AppTypography.title3)

            ForEach(leases) { lease in
                NavigationLink(
                    value: LeaseDestination.detail(lease.id ?? "")
                ) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(
                                lease.rentAmount.formatted(
                                    .currency(code: "EUR")
                                )
                            )
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                            HStack(spacing: AppSpacing.extraSmall) {
                                Text(lease.startDate.formatted(
                                    date: .abbreviated, time: .omitted
                                ))
                                if let endDate = lease.endDate {
                                    Text("— \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                }
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(lease.status.localizedName)
                            .font(AppTypography.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, AppSpacing.small)
                            .padding(.vertical, AppSpacing.extraSmall)
                            .background(leaseStatusColor(lease.status).opacity(0.15))
                            .foregroundStyle(leaseStatusColor(lease.status))
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textLight)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func leaseStatusColor(_ status: LeaseStatus) -> Color {
        switch status {
        case .active: AppTheme.Colors.success
        case .draft: AppTheme.Colors.warning
        case .expired: AppTheme.Colors.error
        case .ended: AppTheme.Colors.textSecondary
        }
    }

    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("tabs.properties")
                .font(AppTypography.title3)

            ForEach(properties) { property in
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: property.type.icon)
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(property.name)
                            .font(AppTypography.body)

                        Text(property.address.formattedShort)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(property.status.localizedName)
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

    private func detailRow(
        icon: String,
        label: LocalizedStringKey,
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

    private func tappableRow(
        icon: String,
        label: LocalizedStringKey,
        value: String,
        url: String
    ) -> some View {
        Button {
            guard let url = URL(string: url) else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 24)

                Text(label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Spacer()

                Text(value)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    private func initials(for tenant: Tenant) -> String {
        let first = tenant.firstName.prefix(1).uppercased()
        let last = tenant.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("tabs.payments")
                .font(AppTypography.title3)

            if payments.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .foregroundStyle(AppTheme.Colors.textLight)

                    Text("properties.no_payments_recorded")
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

    private func loadTenant() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

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

            let allLeases: [Lease] = (
                try? await firestoreService.readAll(
                    from: "leases",
                    whereField: "tenantId",
                    isEqualTo: tenantId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []
            leases = allLeases.filter { $0.status == .active || $0.status == .draft }

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
