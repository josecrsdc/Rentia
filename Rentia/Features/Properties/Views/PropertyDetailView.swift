import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct PropertyDetailView: View {
    let propertyId: String
    @State private var property: Property?
    @State private var tenants: [Tenant] = []
    @State private var activeLease: Lease?
    @State private var pastLeases: [Lease] = []
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
                    Text("common.edit")
                }
            }
        }
        .onAppear { loadProperty() }
        .alert("properties.delete.title",
            isPresented: $showDeleteConfirmation
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                deleteProperty()
            }
        } message: {
            Text("properties.delete.confirmation.message")
        }
    }

    private func propertyContent(_ property: Property) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                propertyHeader(property)
                propertyDetails(property)
                leaseSection(property)
                if !pastLeases.isEmpty {
                    leaseHistorySection(property)
                }
                // tenantsSection
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
            Text("properties.details")
                .font(AppTypography.title3)

            if let description = property.description, !description.isEmpty {
                Text(description)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            detailRow(
                icon: "tag",
                label: "properties.detail.type",
                value: property.type.localizedName
            )

            detailRow(
                icon: "circle.fill",
                label: "properties.detail.status",
                value: activeLease != nil
                    ? "properties.status.rented"
                    : property.status.localizedName
            )

            if let area = property.area {
                detailRow(
                    icon: "square.dashed",
                    label: "properties.area",
                    value: "\(Int(area)) m²"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Lease Section

    private func leaseSection(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            if let activeLease {
                Text("leases.active_contract")
                    .font(AppTypography.title3)

                NavigationLink(
                    value: LeaseDestination.detail(activeLease.id ?? "")
                ) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "doc.text")
                            .font(.title3)
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.Colors.primary.opacity(0.1))
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: AppTheme.CornerRadius.small
                                )
                            )

                        VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                            Text(
                                activeLease.rentAmount.formatted(
                                    .currency(code: property.currency)
                                )
                            )
                            .font(AppTypography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                            HStack(spacing: AppSpacing.extraSmall) {
                                Text(activeLease.startDate.formatted(
                                    date: .abbreviated, time: .omitted
                                ))
                                Text("—")
                                if let endDate = activeLease.endDate {
                                    Text(endDate.formatted(
                                        date: .abbreviated, time: .omitted
                                    ))
                                } else {
                                    Text("leases.indefinite")
                                }
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(activeLease.status.localizedName)
                            .font(AppTypography.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, AppSpacing.small)
                            .padding(.vertical, AppSpacing.extraSmall)
                            .background(AppTheme.Colors.success.opacity(0.15))
                            .foregroundStyle(AppTheme.Colors.success)
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textLight)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("leases.no_active_contract")
                    .font(AppTypography.title3)

                NavigationLink(
                    value: LeaseDestination.formForProperty(propertyId)
                ) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("leases.create_contract")
                    }
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.medium)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Lease History

    private func leaseHistorySection(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("leases.history")
                .font(AppTypography.title3)

            ForEach(pastLeases) { lease in
                NavigationLink(
                    value: LeaseDestination.detail(lease.id ?? "")
                ) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(
                                lease.rentAmount.formatted(
                                    .currency(code: property.currency)
                                )
                            )
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                            HStack(spacing: AppSpacing.extraSmall) {
                                Text(lease.startDate.formatted(
                                    date: .abbreviated, time: .omitted
                                ))
                                Text("—")
                                if let endDate = lease.endDate {
                                    Text(endDate.formatted(
                                        date: .abbreviated, time: .omitted
                                    ))
                                } else {
                                    Text("leases.indefinite")
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

    // MARK: - Tenants Section

    private var tenantsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("tabs.tenants")
                .font(AppTypography.title3)

            if tenants.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "person.2.slash")
                        .foregroundStyle(AppTheme.Colors.textLight)

                    Text("properties.no_assigned_tenants")
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

                    Text(tenant.status.localizedName)
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
        NavigationLink(value: PropertyDestination.payments(propertyId)) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "creditcard")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.CornerRadius.small
                        )
                    )

                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text("tabs.payments")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("properties.view_payments")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private func detailRow(
        icon: String,
        label: LocalizedStringKey,
        value: LocalizedStringKey
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
        if property.type.supportsRoomsBathrooms {
            return AnyView(
                HStack(spacing: AppSpacing.medium) {
                    StatCard(
                        title: "properties.rooms",
                        value: "\(property.rooms)",
                        icon: "bed.double",
                        color: AppTheme.Colors.primary
                    )

                    StatCard(
                        title: "properties.bathrooms",
                        value: "\(property.bathrooms)",
                        icon: "shower",
                        color: AppTheme.Colors.secondary
                    )
                }
            )
        }

        let areaValue = property.area.map { "\(Int($0)) m²" } ?? "—"
        return AnyView(
            HStack(spacing: AppSpacing.medium) {
                StatCard(
                    title: "properties.area",
                    value: areaValue,
                    icon: "square.dashed",
                    color: AppTheme.Colors.primary
                )
            }
        )
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
                Text("properties.delete.title")
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
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                property = try await firestoreService.read(
                    id: propertyId,
                    from: "properties"
                )
            } catch {
                // Handle error
            }

            tenants = (
                try? await firestoreService.readAll(
                    from: "tenants",
                    whereField: "propertyIds",
                    arrayContains: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            let allLeases: [Lease] = (
                try? await firestoreService.readAll(
                    from: "leases",
                    whereField: "propertyId",
                    isEqualTo: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []
            activeLease = allLeases.first { $0.status == .active }
            pastLeases = allLeases
                .filter { $0.status != .active }
                .sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }

            isLoading = false
        }
    }
}
