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
                ? "tenants.editar_inquilino"
                : "tenants.nuevo_inquilino"
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
        .alert("common.error",
            isPresented: $viewModel.showError
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var personalInfoSection: some View {
        Section("tenants.informacion_personal") {
            TextField(
                "tenants.nombre",
                text: $viewModel.firstName
            )

            TextField(
                "tenants.apellido",
                text: $viewModel.lastName
            )

            TextField(
                "tenants.numero_de_identificacion",
                text: $viewModel.idNumber
            )
        }
    }

    private var contactSection: some View {
        Section("tenants.contacto") {
            TextField(
                "tenants.email",
                text: $viewModel.email
            )
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()

            TextField(
                "tenants.telefono",
                text: $viewModel.phone
            )
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
        }
    }

    private var propertiesSection: some View {
        Section {
            if viewModel.availableProperties.isEmpty {
                Text("tenants.no_hay_propiedades_registradas")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            } else {
                ForEach(viewModel.availableProperties) { property in
                    propertyRow(property)
                }
            }
        } header: {
            Text("tabs.properties")
        } footer: {
            if !viewModel.availableProperties.isEmpty {
                Text(
                    "tenants.selecciona_las_propiedades_asociadas_a_este_inquilino"
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
        Section("tenants.contrato") {
            DatePicker("tenants.inicio_del_contrato",
                selection: $viewModel.leaseStartDate,
                displayedComponents: .date
            )

            DatePicker("tenants.fin_del_contrato",
                selection: $viewModel.leaseEndDate,
                displayedComponents: .date
            )

            TextField(
                "properties.renta_mensual",
                text: $viewModel.monthlyRent
            )
            .keyboardType(.decimalPad)

            TextField(
                "tenants.deposito",
                text: $viewModel.depositAmount
            )
            .keyboardType(.decimalPad)

            Picker("properties.estado",
                selection: $viewModel.status
            ) {
                ForEach(TenantStatus.allCases, id: \.self) { status in
                    Text(LocalizedStringKey(status.displayNameKey)).tag(status)
                }
            }
        }
    }

    private var saveButton: some View {
        Section {
            PrimaryButton(
                title: viewModel.isEditing
                    ? "common.save_changes"
                    : "tenants.agregar_inquilino",
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
