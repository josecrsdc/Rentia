import SwiftUI

struct PropertyFormView: View {
    let propertyId: String?
    var onSaved: ((String) -> Void)?
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
                ? "properties.edit.title"
                : "properties.new.title"
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let propertyId {
                viewModel.loadProperty(id: propertyId)
            }
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
        .onChange(of: viewModel.type) {
            viewModel.normalizeRoomsBathroomsForType()
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
        Section("properties.basic_information") {
            TextField(
                "properties.name",
                text: $viewModel.name
            )

            NavigationLink {
                AddressSearchView(address: $viewModel.address)
            } label: {
                HStack {
                    Text("properties.address")
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    Spacer()

                    if viewModel.address.street.isNotEmpty {
                        Text(viewModel.address.formattedShort)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                    } else {
                        Text("properties.address.tap_to_search")
                            .foregroundStyle(AppTheme.Colors.textLight)
                    }
                }
            }

            Picker("properties.type",
                selection: $viewModel.type
            ) {
                ForEach(PropertyType.allCases, id: \.self) { type in
                    Label(type.localizedName, systemImage: type.icon)
                        .tag(type)
                }
            }

            Picker("properties.status",
                selection: $viewModel.status
            ) {
                ForEach(PropertyStatus.allCases, id: \.self) { status in
                    Text(status.localizedName).tag(status)
                }
            }
        }
    }

    private var financialSection: some View {
        Section("properties.financial_information") {
            Picker("properties.currency",
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
        Section("properties.details") {
            if viewModel.type.supportsRoomsBathrooms {
                TextField(
                    "properties.rooms",
                    text: $viewModel.rooms
                )
                .keyboardType(.numberPad)

                TextField(
                    "properties.bathrooms",
                    text: $viewModel.bathrooms
                )
                .keyboardType(.numberPad)
            }

            TextField(
                "properties.area_m2",
                text: $viewModel.area
            )
            .keyboardType(.decimalPad)

            TextField(
                "properties.description",
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
                    : "properties.create",
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
