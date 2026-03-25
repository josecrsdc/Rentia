import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct LeaseDetailView: View {
    let leaseId: String
    @State private var lease: Lease?
    @State private var propertyName: String?
    @State private var tenantName: String?
    @State private var leasePayments: [Payment] = []
    @State private var isLoading = true
    @State private var showStatusError = false
    @State private var statusErrorMessage = ""
    @State private var pendingStatusChange: LeaseStatus?
    @State private var showPendingPaymentsDialog = false
    @Environment(\.dismiss)
    private var dismiss

    private let firestoreService = FirestoreService()
    private let coordinator = LeaseCoordinator()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let lease {
                leaseContent(lease)
            }
        }
        .navigationTitle("leases.detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: LeaseDestination.form(leaseId)) {
                    Text("common.edit")
                }
            }
        }
        .onAppear { loadLease() }
        .alert("common.error", isPresented: $showStatusError) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(statusErrorMessage)
        }
        .confirmationDialog(
            String(localized: "leases.pending_payments_dialog.title"),
            isPresented: $showPendingPaymentsDialog,
            titleVisibility: .visible
        ) {
            Button(String(localized: "leases.pending_payments.delete"), role: .destructive) {
                guard let status = pendingStatusChange else { return }
                pendingStatusChange = nil
                updateStatus(status, deletePending: true)
            }
            Button(String(localized: "leases.pending_payments.keep")) {
                guard let status = pendingStatusChange else { return }
                pendingStatusChange = nil
                updateStatus(status, deletePending: false)
            }
            Button("common.cancel", role: .cancel) {
                pendingStatusChange = nil
            }
        } message: {
            Text("leases.pending_payments_dialog.message")
        }
    }

    // MARK: - Content

    private func leaseContent(_ lease: Lease) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                headerCard(lease)
                datesCard(lease)
                financialCard(lease)
                detailsCard(lease)
                relatedInfoCard(lease)
                paymentsSection
                DocumentListView(entityId: leaseId, entityType: .lease)
                actionButtons(lease)
            }
            .padding(AppSpacing.medium)
        }
    }

    // MARK: - Header Card

    private func headerCard(_ lease: Lease) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            statusBadge(lease.status)

            Text(lease.rentAmount.formatted(.currency(code: "EUR")))
                .font(AppTypography.moneyLarge)
                .foregroundStyle(AppTheme.Colors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func statusBadge(_ status: LeaseStatus) -> some View {
        Text(status.localizedName)
            .font(AppTypography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.extraSmall)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: LeaseStatus) -> Color {
        switch status {
        case .active: AppTheme.Colors.success
        case .draft: AppTheme.Colors.warning
        case .expired: AppTheme.Colors.error
        case .ended: AppTheme.Colors.textSecondary
        }
    }

    // MARK: - Dates Card

    private func datesCard(_ lease: Lease) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("leases.dates")
                .font(AppTypography.title3)

            detailRow(
                icon: "calendar",
                label: "leases.start_date",
                value: lease.startDate.formatted(date: .abbreviated, time: .omitted)
            )

            detailRow(
                icon: "calendar.badge.clock",
                label: "leases.end_date",
                value: lease.endDate?.formatted(date: .abbreviated, time: .omitted)
                    ?? String(localized: "leases.indefinite")
            )

            detailRow(
                icon: "clock",
                label: "leases.billing_day",
                value: "\(lease.billingDay)"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Financial Card

    private func financialCard(_ lease: Lease) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("leases.financial")
                .font(AppTypography.title3)

            detailRow(
                icon: "banknote",
                label: "leases.rent_amount",
                value: lease.rentAmount.formatted(.currency(code: "EUR"))
            )

            detailRow(
                icon: "lock.shield",
                label: "leases.deposit_amount",
                value: lease.depositAmount.formatted(.currency(code: "EUR"))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Details Card

    private func detailsCard(_ lease: Lease) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("leases.details")
                .font(AppTypography.title3)

            detailRow(
                icon: "bolt",
                label: "leases.utilities_mode",
                value: utilitiesModeText(lease.utilitiesMode)
            )

            if let notes = lease.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .frame(width: 24)

                        Text("leases.notes")
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }

                    Text(notes)
                        .font(AppTypography.body)
                        .padding(.leading, 32)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Related Info

    private func relatedInfoCard(_ lease: Lease) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            if let propertyName {
                NavigationLink(value: PropertyDestination.detail(lease.propertyId)) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "building.2")
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 24)

                        Text(propertyName)
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textLight)
                    }
                }
                .buttonStyle(.plain)
            }

            if let tenantName {
                NavigationLink(value: TenantDestination.detail(lease.tenantId)) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "person")
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 24)

                        Text(tenantName)
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Spacer()

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

    // MARK: - Payments Section

    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("leases.payments_section")
                .font(AppTypography.title3)

            if leasePayments.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .foregroundStyle(AppTheme.Colors.textLight)

                    Text("properties.no_payments_recorded")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            } else {
                ForEach(leasePayments) { payment in
                    NavigationLink(value: PaymentDestination.detail(payment.id ?? "")) {
                        PaymentCard(payment: payment)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Action Buttons

    private func actionButtons(_ lease: Lease) -> some View {
        VStack(spacing: AppSpacing.small) {
            if lease.status == .draft {
                actionButton(
                    title: "leases.activate",
                    icon: "checkmark.circle",
                    color: AppTheme.Colors.success
                ) {
                    requestStatusChange(.active)
                }
            }

            if lease.status == .active || lease.status == .draft {
                actionButton(
                    title: "leases.finalize",
                    icon: "xmark.circle",
                    color: AppTheme.Colors.warning
                ) {
                    requestStatusChange(.ended)
                }
            }

            if lease.status == .active {
                actionButton(
                    title: "leases.mark_expired",
                    icon: "clock.badge.exclamationmark",
                    color: AppTheme.Colors.error
                ) {
                    requestStatusChange(.expired)
                }
            }
        }
    }

    private func actionButton(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(AppTypography.body)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.medium)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        }
    }

    // MARK: - Helpers

    private func utilitiesModeText(_ mode: UtilitiesMode) -> String {
        switch mode {
        case .included: String(localized: "leases.utilities.included")
        case .manual: String(localized: "leases.utilities.manual")
        case .none: String(localized: "leases.utilities.none")
        }
    }

    private func detailRow(icon: String, label: LocalizedStringKey, value: String) -> some View {
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

    // MARK: - Data

    private func loadLease() {
        Task {
            do {
                let loadedLease: Lease = try await firestoreService.read(
                    id: leaseId,
                    from: "leases"
                )
                lease = loadedLease

                async let propertyResult: Property? = try? firestoreService.read(
                    id: loadedLease.propertyId,
                    from: "properties"
                )
                async let tenantResult: Tenant? = try? firestoreService.read(
                    id: loadedLease.tenantId,
                    from: "tenants"
                )
                async let paymentsResult: [Payment] = (
                    try? firestoreService.readAll(
                        from: "payments",
                        whereField: "leaseId",
                        isEqualTo: leaseId
                    )
                ) ?? []

                if let property = await propertyResult { propertyName = property.name }
                if let tenant = await tenantResult { tenantName = tenant.fullName }
                leasePayments = await paymentsResult.sorted { $0.dueDate < $1.dueDate }
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }

    // MARK: - Status Changes

    private func requestStatusChange(_ newStatus: LeaseStatus) {
        guard newStatus == .ended || newStatus == .expired else {
            updateStatus(newStatus, deletePending: false)
            return
        }

        let hasPending = leasePayments.contains { $0.status == .pending || $0.status == .overdue }
        if hasPending {
            pendingStatusChange = newStatus
            showPendingPaymentsDialog = true
        } else {
            updateStatus(newStatus, deletePending: false)
        }
    }

    private func updateStatus(_ newStatus: LeaseStatus, deletePending: Bool) {
        guard let currentLease = lease,
              let userId = Auth.auth().currentUser?.uid else { return }
        var updatedLease = currentLease
        updatedLease.status = newStatus
        updatedLease.updatedAt = Date()

        Task {
            do {
                try await firestoreService.update(updatedLease, id: leaseId, in: "leases")
                lease = updatedLease

                if newStatus == .active {
                    try? await coordinator.onActivated(lease: updatedLease, ownerId: userId)
                } else if newStatus == .ended || newStatus == .expired {
                    try? await handleDeactivation(
                        lease: updatedLease,
                        ownerId: userId,
                        deletePending: deletePending
                    )
                }

                leasePayments = (
                    (try? await firestoreService.readAll(
                        from: "payments",
                        whereField: "leaseId",
                        isEqualTo: leaseId
                    )) ?? []
                ).sorted { $0.dueDate < $1.dueDate }
            } catch {
                statusErrorMessage = error.localizedDescription
                showStatusError = true
            }
        }
    }

    private func handleDeactivation(lease: Lease, ownerId: String, deletePending: Bool) async throws {
        if deletePending {
            for payment in leasePayments where payment.status == .pending || payment.status == .overdue {
                guard let paymentId = payment.id else { continue }
                try? await firestoreService.delete(id: paymentId, from: "payments")
            }
        }
        try? await coordinator.onDeactivated(
            lease: lease,
            ownerId: ownerId,
            skipPaymentCancellation: true
        )
    }
}
