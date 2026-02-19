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
                financialSection
                detailsSection
                saveButton
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(
            propertyId != nil
                ? String(localized: "Editar Propiedad")
                : String(localized: "Nueva Propiedad")
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let propertyId {
                viewModel.loadProperty(id: propertyId)
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

    private var basicInfoSection: some View {
        Section(String(localized: "Informacion Basica")) {
            TextField(
                String(localized: "Nombre de la propiedad"),
                text: $viewModel.name
            )

            TextField(
                String(localized: "Direccion"),
                text: $viewModel.address
            )

            Picker(
                String(localized: "Tipo"),
                selection: $viewModel.type
            ) {
                ForEach(PropertyType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }

            Picker(
                String(localized: "Estado"),
                selection: $viewModel.status
            ) {
                ForEach(PropertyStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
        }
    }

    private var financialSection: some View {
        Section(String(localized: "Informacion Financiera")) {
            TextField(
                String(localized: "Renta mensual"),
                text: $viewModel.monthlyRent
            )
            .keyboardType(.decimalPad)

            Picker(
                String(localized: "Moneda"),
                selection: $viewModel.currency
            ) {
                Text("USD").tag("USD")
                Text("EUR").tag("EUR")
                Text("MXN").tag("MXN")
                Text("COP").tag("COP")
            }
        }
    }

    private var detailsSection: some View {
        Section(String(localized: "Detalles")) {
            TextField(
                String(localized: "Habitaciones"),
                text: $viewModel.rooms
            )
            .keyboardType(.numberPad)

            TextField(
                String(localized: "Banos"),
                text: $viewModel.bathrooms
            )
            .keyboardType(.numberPad)

            TextField(
                String(localized: "Area (m²)"),
                text: $viewModel.area
            )
            .keyboardType(.decimalPad)

            TextField(
                String(localized: "Descripcion"),
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
                    ? String(localized: "Guardar Cambios")
                    : String(localized: "Crear Propiedad"),
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
