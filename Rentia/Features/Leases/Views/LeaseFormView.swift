import SwiftUI

struct LeaseFormView: View {
    let leaseId: String?
    var propertyId: String?
    var tenantId: String?
    var onSaved: ((String) -> Void)?
    @State private var viewModel = LeaseFormViewModel()
    @Environment(\.dismiss) private var dismiss

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
        Section("leases.dates") {
            DatePicker(
                "leases.start_date",
                selection: $viewModel.startDate,
                displayedComponents: .date
            )

            Toggle("leases.has_end_date", isOn: $viewModel.hasEndDate)

            if viewModel.hasEndDate {
                DatePicker(
                    "leases.end_date",
                    selection: $viewModel.endDate,
                    in: viewModel.startDate...,
                    displayedComponents: .date
                )
            }
        }
    }

    private var financialSection: some View {
        Section("leases.financial") {
            TextField(
                "leases.rent_amount",
                text: $viewModel.rentAmount
            )
            .keyboardType(.decimalPad)

            TextField(
                "leases.deposit_amount",
                text: $viewModel.depositAmount
            )
            .keyboardType(.decimalPad)

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

            Picker("leases.status",
                selection: $viewModel.status
            ) {
                ForEach(LeaseStatus.allCases, id: \.self) { status in
                    Text(status.localizedName).tag(status)
                }
            }

            TextField(
                "leases.notes",
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }

    private var saveButton: some View {
        Section {
            PrimaryButton(
                title: viewModel.isEditing
                    ? "common.save_changes"
                    : "leases.create",
                isLoading: viewModel.isLoading
            ) {
                viewModel.save()
            }
            .disabled(!viewModel.isFormValid)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
}
