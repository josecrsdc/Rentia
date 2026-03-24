import SwiftUI

struct PaymentFormView: View {
    let paymentId: String?
    @State private var viewModel = PaymentFormViewModel()
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss)
    private var dismiss

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Form {
                selectionSection
                amountSection
                datesSection
                additionalSection
                saveButton
                if paymentId != nil {
                    deleteSection
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(
            paymentId != nil
                ? "payments.edit.title"
                : "payments.new.title"
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
            if let paymentId {
                viewModel.loadPayment(id: paymentId)
            }
        }
        .onChange(of: viewModel.didSave) {
            if viewModel.didSave { dismiss() }
        }
        .alert("common.error",
            isPresented: $viewModel.showError
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("payments.delete.title",
            isPresented: $showDeleteConfirmation
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                deletePayment()
            }
        } message: {
            Text("payments.delete.confirmation.message")
        }
    }

    // MARK: - Sections

    private var selectionSection: some View {
        Section("payments.assignment") {
            Picker("properties.tenant",
                selection: $viewModel.tenantId
            ) {
                Text("common.select").tag("")
                ForEach(viewModel.tenants) { tenant in
                    Text(tenant.fullName).tag(tenant.id ?? "")
                }
            }

            Picker("payments.property",
                selection: $viewModel.propertyId
            ) {
                Text("common.select").tag("")
                ForEach(viewModel.properties) { property in
                    Text(property.name).tag(property.id ?? "")
                }
            }
        }
    }

    private var amountSection: some View {
        Section("payments.amount") {
            TextField(
                "payments.amount",
                text: $viewModel.amount
            )
            .keyboardType(.decimalPad)

            Picker("properties.status",
                selection: $viewModel.status
            ) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Text(status.localizedName).tag(status)
                }
            }
        }
    }

    private var datesSection: some View {
        Section("payments.dates") {
            DatePicker("payments.payment_date",
                selection: $viewModel.date,
                displayedComponents: .date
            )

            DatePicker("payments.due_date",
                selection: $viewModel.dueDate,
                displayedComponents: .date
            )
        }
    }

    private var additionalSection: some View {
        Section("payments.additional") {
            TextField(
                "payments.payment_method",
                text: $viewModel.paymentMethod
            )

            TextField(
                "payments.notes",
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }

    private var deleteSection: some View {
        Section {
            DeleteButton(title: "payments.delete.title") {
                showDeleteConfirmation = true
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private func deletePayment() {
        guard let paymentId else { return }
        Task {
            do {
                try await firestoreService.delete(id: paymentId, from: "payments")
                dismiss()
            } catch {
                // Handle error
            }
        }
    }

    private var saveButton: some View {
        Section {
            PrimaryButton(
                title: viewModel.isEditing
                    ? "common.save_changes"
                    : "payments.record",
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
