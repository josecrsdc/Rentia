import SwiftUI

struct PropertyFormView: View {
    let propertyId: String?
    @State private var viewModel = PropertyFormViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Form {
                basicInfoSection
                if viewModel.status == .rented {
                    tenantSection
                }
                financialSection
                detailsSection
                saveButton
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(
            propertyId != nil
                ? "properties.editar_propiedad"
                : "properties.nueva_propiedad"
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadTenants()
            if let propertyId {
                viewModel.loadProperty(id: propertyId)
            }
        }
        .onChange(of: viewModel.didSave) {
            if viewModel.didSave { dismiss() }
        }
        .onChange(of: viewModel.status) {
            viewModel.clearTenantIfNeeded()
        }
        .onChange(of: viewModel.type) {
            viewModel.normalizeRoomsBathroomsForType()
        }
        .sheet(isPresented: $viewModel.showCreateTenant) {
            viewModel.loadTenants()
        } content: {
            NavigationStack {
                TenantFormView(tenantId: nil)
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

    private var basicInfoSection: some View {
        Section("properties.informacion_basica") {
            TextField(
                "properties.nombre_de_la_propiedad",
                text: $viewModel.name
            )

            TextField(
                "properties.direccion",
                text: $viewModel.address
            )

            Picker("properties.tipo",
                selection: $viewModel.type
            ) {
                ForEach(PropertyType.allCases, id: \.self) { type in
                    Label(type.displayNameKey, systemImage: type.icon)
                        .tag(type)
                }
            }

            Picker("properties.estado",
                selection: $viewModel.status
            ) {
                ForEach(PropertyStatus.allCases, id: \.self) { status in
                    Text(status.displayNameKey).tag(status)
                }
            }
        }
    }

    private var tenantSection: some View {
        Section {
            if viewModel.tenants.isEmpty {
                VStack(spacing: AppSpacing.medium) {
                    Text("properties.no_hay_inquilinos_registrados")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    Button {
                        viewModel.showCreateTenant = true
                    } label: {
                        Label(
                            "properties.crear_inquilino",
                            systemImage: "person.badge.plus"
                        )
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.small)
            } else {
                Picker("properties.inquilino",
                    selection: $viewModel.selectedTenantId
                ) {
                    Text("common.select")
                        .tag(nil as String?)
                    ForEach(viewModel.tenants) { tenant in
                        Text(tenant.fullName).tag(tenant.id as String?)
                    }
                }

                Button {
                    viewModel.showCreateTenant = true
                } label: {
                    Label(
                        "properties.crear_nuevo_inquilino",
                        systemImage: "person.badge.plus"
                    )
                    .font(AppTypography.caption)
                }
            }
        } header: {
            Text("properties.inquilino")
        } footer: {
            Text(
                "properties.selecciona_el_inquilino_que_alquila_esta_propiedad"
            )
        }
    }

    private var financialSection: some View {
        Section("properties.informacion_financiera") {
            TextField(
                "properties.renta_mensual",
                text: $viewModel.monthlyRent
            )
            .keyboardType(.decimalPad)

            Picker("properties.moneda",
                selection: $viewModel.currency
            ) {
                Text("properties.usd").tag("USD")
                Text("properties.eur").tag("EUR")
                Text("properties.mxn").tag("MXN")
                Text("properties.cop").tag("COP")
            }
        }
    }

    private var detailsSection: some View {
        Section("properties.detalles") {
            if viewModel.type.supportsRoomsBathrooms {
                TextField(
                    "properties.habitaciones",
                    text: $viewModel.rooms
                )
                .keyboardType(.numberPad)

                TextField(
                    "properties.banos",
                    text: $viewModel.bathrooms
                )
                .keyboardType(.numberPad)
            }

            TextField(
                "properties.area_m",
                text: $viewModel.area
            )
            .keyboardType(.decimalPad)

            TextField(
                "properties.descripcion",
                text: $viewModel.propertyDescription,
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
                    : "properties.crear_propiedad",
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
