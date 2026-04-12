import SwiftUI

struct LeaseFormView: View {
    let leaseId: String?
    var propertyId: String?
    var tenantId: String?
    var onSaved: ((String) -> Void)?
    var onDeleted: (() -> Void)?
    @State private var viewModel = LeaseFormViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showStatusChangeDialog = false
    @State private var showIrreversibleWarning = false
    @State private var pendingIrreversibleStatus: LeaseStatus?
    @State private var pendingPaymentsForSave: [Payment] = []
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Form {
                if !viewModel.hidePropertySelector || !viewModel.hideTenantSelector {
                    assignmentSection
                }
                datesSection
                financialSection
                detailsSection
                saveButton
                if leaseId != nil {
                    deleteSection
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(
            leaseId != nil
                ? "leases.edit.title"
                : "leases.new.title"
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let leaseId {
                viewModel.loadLease(id: leaseId)
            } else if let propertyId, let tenantId {
                viewModel.configure(
                    propertyId: propertyId,
                    tenantId: tenantId,
                    rent: 0,
                    currency: ""
                )
            } else if let propertyId {
                viewModel.propertyId = propertyId
                viewModel.preAssignedPropertyId = propertyId
            }
            viewModel.loadData()
        }
        .onChange(of: viewModel.didSave) {
            if viewModel.didSave {
                if let onSaved, let savedId = viewModel.savedId {
                    onSaved(savedId)
                } else {
                    dismiss()
                }
            }
        }
        .alert("common.error",
            isPresented: $viewModel.showError
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("leases.delete.title",
            isPresented: $showDeleteConfirmation
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("leases.delete.only_lease", role: .destructive) {
                viewModel.delete(alsoDeletePayments: false)
            }
            Button("leases.delete.with_payments", role: .destructive) {
                viewModel.delete(alsoDeletePayments: true)
            }
        } message: {
            Text("leases.delete.payments_question")
        }
        .onChange(of: viewModel.didDelete) {
            if viewModel.didDelete {
                if let onDeleted {
                    onDeleted()
                } else {
                    dismiss()
                }
            }
        }
        .confirmationDialog(
            String(localized: "leases.pending_payments_dialog.title"),
            isPresented: $showStatusChangeDialog,
            titleVisibility: .visible
        ) {
            Button(String(localized: "leases.pending_payments.delete"), role: .destructive) {
                Task { await deleteFutureAndSave() }
            }
            Button(String(localized: "leases.pending_payments.keep")) {
                viewModel.save()
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: {
            Text("leases.pending_payments_dialog.message")
        }
        .alert(
            String(localized: "leases.status.irreversible_warning.title"),
            isPresented: $showIrreversibleWarning
        ) {
            Button(
                String(localized: "leases.status.irreversible_warning.confirm"),
                role: .destructive
            ) {
                if let pending = pendingIrreversibleStatus {
                    viewModel.status = pending
                }
                pendingIrreversibleStatus = nil
            }
            Button(String(localized: "common.cancel"), role: .cancel) {
                pendingIrreversibleStatus = nil
            }
        } message: {
            Text("leases.status.irreversible_warning.message")
        }
    }

    // MARK: - Sections

    private var assignmentSection: some View {
        Section("leases.assignment") {
            if !viewModel.hidePropertySelector {
                Picker("leases.property", selection: $viewModel.propertyId) {
                    Text("leases.select_property").tag("")
                    ForEach(viewModel.availableProperties) { property in
                        Text(property.name).tag(property.id ?? "")
                    }
                }
            }

            if !viewModel.hideTenantSelector {
                Picker("leases.tenant", selection: $viewModel.tenantId) {
                    Text("leases.select_tenant").tag("")
                    ForEach(viewModel.availableTenants) { tenant in
                        Text(tenant.fullName).tag(tenant.id ?? "")
                    }
                }
            }
        }
    }

    private var datesSection: some View {
        let locked = viewModel.hasGeneratedPayments
        let hint = locked ? String(localized: "leases.dates.locked_hint") : ""
        return Section {
            DatePicker(
                "leases.start_date",
                selection: $viewModel.startDate,
                displayedComponents: .date
            )
            .disabled(locked)
            .accessibilityHint(hint)

            Toggle("leases.has_end_date", isOn: $viewModel.hasEndDate)
                .disabled(locked)
                .accessibilityHint(hint)

            if viewModel.hasEndDate {
                DatePicker(
                    "leases.end_date",
                    selection: $viewModel.endDate,
                    in: viewModel.startDate...,
                    displayedComponents: .date
                )
                .disabled(locked)
                .accessibilityHint(hint)
            }

            if locked {
                Label("leases.dates.locked_hint", systemImage: "lock.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            } else if !viewModel.isEditing {
                Text("leases.create.dates_hint")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        } header: {
            Text("leases.dates")
        }
    }

    private var financialSection: some View {
        Section("leases.financial") {
            Picker("leases.currency", selection: $viewModel.currency) {
                Text("€ Euro").tag("EUR")
                Text("$ Dólar").tag("USD")
            }
            .pickerStyle(.segmented)

            HStack {
                Text(viewModel.currency == "EUR" ? "€" : "$")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 16)
                TextField(
                    "leases.rent_amount",
                    text: $viewModel.rentAmount
                )
                .keyboardType(.decimalPad)
            }

            HStack {
                Text(viewModel.currency == "EUR" ? "€" : "$")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 16)
                TextField(
                    "leases.deposit_amount",
                    text: $viewModel.depositAmount
                )
                .keyboardType(.decimalPad)
            }

            Stepper(
                "leases.billing_day \(viewModel.billingDay)",
                value: $viewModel.billingDay,
                in: 1...28
            )
        }
    }

    private var detailsSection: some View {
        Section("leases.details") {
            Picker("leases.utilities_mode",
                selection: $viewModel.utilitiesMode
            ) {
                ForEach(UtilitiesMode.allCases, id: \.self) { mode in
                    Text(mode.localizedName).tag(mode)
                }
            }

            Picker("leases.status", selection: Binding(
                get: { viewModel.status },
                set: { newStatus in
                    if newStatus.isTerminal && !viewModel.status.isTerminal {
                        pendingIrreversibleStatus = newStatus
                        showIrreversibleWarning = true
                    } else {
                        viewModel.status = newStatus
                    }
                }
            )) {
                ForEach(viewModel.availableStatuses, id: \.self) { status in
                    Text(status.localizedName).tag(status)
                }
            }
            .disabled(viewModel.originalStatus?.isTerminal == true)

            TextField(
                "leases.notes",
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }

    private var deleteSection: some View {
        Section {
            DeleteButton(title: "leases.delete.title") {
                showDeleteConfirmation = true
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var saveButton: some View {
        Section {
            PrimaryButton(
                title: viewModel.isEditing ? "common.save_changes" : "leases.create",
                isLoading: viewModel.isLoading
            ) {
                Task { await checkAndSave() }
            }
            .disabled(!viewModel.isFormValid)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private func checkAndSave() async {
        let isDeactivation = (viewModel.status == .ended || viewModel.status == .expired)
            && viewModel.isEditing
        guard isDeactivation else {
            viewModel.save()
            return
        }
        pendingPaymentsForSave = await viewModel.fetchPendingPayments()
        if pendingPaymentsForSave.isEmpty {
            viewModel.save()
        } else {
            showStatusChangeDialog = true
        }
    }

    private func deleteFutureAndSave() async {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: Date())
        comps.day = 1
        let startOfThisMonth = calendar.date(from: comps) ?? Date()
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfThisMonth) ?? Date()
        await viewModel.deleteFuturePayments(pendingPaymentsForSave, from: startOfNextMonth)
        viewModel.save()
    }
}
