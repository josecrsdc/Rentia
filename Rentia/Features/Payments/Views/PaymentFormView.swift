import SwiftUI

struct PaymentFormView: View {
    let paymentId: String?
    @State private var viewModel = PaymentFormViewModel()
    @Environment(\.dismiss) private var dismiss

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
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(
            paymentId != nil
                ? "payments.editar_pago"
                : "payments.nuevo_pago"
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
    }

    // MARK: - Sections

    private var selectionSection: some View {
        Section("payments.asignacion") {
            Picker("properties.inquilino",
                selection: $viewModel.tenantId
            ) {
                Text("common.select").tag("")
                ForEach(viewModel.tenants) { tenant in
                    Text(tenant.fullName).tag(tenant.id ?? "")
                }
            }

            Picker("payments.propiedad",
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
        Section("payments.monto") {
            TextField(
                "payments.cantidad",
                text: $viewModel.amount
            )
            .keyboardType(.decimalPad)

            Picker("properties.estado",
                selection: $viewModel.status
            ) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Text(status.displayNameKey).tag(status)
                }
            }
        }
    }

    private var datesSection: some View {
        Section("payments.fechas") {
            DatePicker("payments.fecha_de_pago",
                selection: $viewModel.date,
                displayedComponents: .date
            )

            DatePicker("payments.fecha_de_vencimiento",
                selection: $viewModel.dueDate,
                displayedComponents: .date
            )
        }
    }

    private var additionalSection: some View {
        Section("payments.adicional") {
            TextField(
                "payments.metodo_de_pago",
                text: $viewModel.paymentMethod
            )

            TextField(
                "payments.notas",
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
                    : "payments.registrar_pago",
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
