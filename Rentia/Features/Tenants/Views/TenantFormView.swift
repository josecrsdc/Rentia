import SwiftUI

struct TenantFormView: View {
    let tenantId: String?
    @State private var viewModel = TenantFormViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Form {
                personalInfoSection
                contactSection
                propertiesSection
                leaseSection
                saveButton
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(
            tenantId != nil
                ? String(localized: "Editar Inquilino")
                : String(localized: "Nuevo Inquilino")
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadProperties()
            if let tenantId {
                viewModel.loadTenant(id: tenantId)
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

    private var personalInfoSection: some View {
        Section(String(localized: "Informacion Personal")) {
            TextField(
                String(localized: "Nombre"),
                text: $viewModel.firstName
            )

            TextField(
                String(localized: "Apellido"),
                text: $viewModel.lastName
            )

            TextField(
                String(localized: "Numero de Identificacion"),
                text: $viewModel.idNumber
            )
        }
    }

    private var contactSection: some View {
        Section(String(localized: "Contacto")) {
            TextField(
                String(localized: "Email"),
                text: $viewModel.email
            )
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()

            TextField(
                String(localized: "Telefono"),
                text: $viewModel.phone
            )
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
        }
    }

    private var propertiesSection: some View {
        Section {
            if viewModel.availableProperties.isEmpty {
                Text(String(localized: "No hay propiedades registradas"))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            } else {
                ForEach(viewModel.availableProperties) { property in
                    propertyRow(property)
                }
            }
        } header: {
            Text(String(localized: "Propiedades"))
        } footer: {
            if !viewModel.availableProperties.isEmpty {
                Text(
                    String(localized: "Selecciona las propiedades asociadas a este inquilino")
                )
            }
        }
    }

    private func propertyRow(_ property: Property) -> some View {
        Button {
            if let propertyId = property.id {
                viewModel.toggleProperty(propertyId)
            }
        } label: {
            HStack {
                Image(systemName: property.type.icon)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(property.name)
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text(property.address)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if let propertyId = property.id,
                   viewModel.isPropertySelected(propertyId) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(AppTheme.Colors.textLight)
                }
            }
        }
    }

    private var leaseSection: some View {
        Section(String(localized: "Contrato")) {
            DatePicker(
                String(localized: "Inicio del contrato"),
                selection: $viewModel.leaseStartDate,
                displayedComponents: .date
            )

            DatePicker(
                String(localized: "Fin del contrato"),
                selection: $viewModel.leaseEndDate,
                displayedComponents: .date
            )

            TextField(
                String(localized: "Renta mensual"),
                text: $viewModel.monthlyRent
            )
            .keyboardType(.decimalPad)

            TextField(
                String(localized: "Deposito"),
                text: $viewModel.depositAmount
            )
            .keyboardType(.decimalPad)

            Picker(
                String(localized: "Estado"),
                selection: $viewModel.status
            ) {
                ForEach(TenantStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
        }
    }

    private var saveButton: some View {
        Section {
            PrimaryButton(
                title: viewModel.isEditing
                    ? String(localized: "Guardar Cambios")
                    : String(localized: "Agregar Inquilino"),
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
