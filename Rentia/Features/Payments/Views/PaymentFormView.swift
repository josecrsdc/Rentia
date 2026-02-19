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
                ? String(localized: "Editar Pago")
                : String(localized: "Nuevo Pago")
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
        .alert(
            String(localized: "Error"),
            isPresented: $viewModel.showError
        ) {
            Button(String(localized: "Aceptar"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var selectionSection: some View {
        Section(String(localized: "Asignacion")) {
            Picker(
                String(localized: "Inquilino"),
                selection: $viewModel.tenantId
            ) {
                Text(String(localized: "Seleccionar")).tag("")
                ForEach(viewModel.tenants) { tenant in
                    Text(tenant.fullName).tag(tenant.id ?? "")
                }
            }

            Picker(
                String(localized: "Propiedad"),
                selection: $viewModel.propertyId
            ) {
                Text(String(localized: "Seleccionar")).tag("")
                ForEach(viewModel.properties) { property in
                    Text(property.name).tag(property.id ?? "")
                }
            }
        }
    }

    private var amountSection: some View {
        Section(String(localized: "Monto")) {
            TextField(
                String(localized: "Cantidad"),
                text: $viewModel.amount
            )
            .keyboardType(.decimalPad)

            Picker(
                String(localized: "Estado"),
                selection: $viewModel.status
            ) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
        }
    }

    private var datesSection: some View {
        Section(String(localized: "Fechas")) {
            DatePicker(
                String(localized: "Fecha de pago"),
                selection: $viewModel.date,
                displayedComponents: .date
            )

            DatePicker(
                String(localized: "Fecha de vencimiento"),
                selection: $viewModel.dueDate,
                displayedComponents: .date
            )
        }
    }

    private var additionalSection: some View {
        Section(String(localized: "Adicional")) {
            TextField(
                String(localized: "Metodo de pago"),
                text: $viewModel.paymentMethod
            )

            TextField(
                String(localized: "Notas"),
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
                    ? String(localized: "Guardar Cambios")
                    : String(localized: "Registrar Pago"),
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
