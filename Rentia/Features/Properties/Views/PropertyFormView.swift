import SwiftUI

struct PropertyFormView: View {
    let propertyId: String?
    var onSaved: ((String) -> Void)?
    var onDeleted: (() -> Void)?
    @State private var viewModel = PropertyFormViewModel()
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss)
    private var dismiss

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Form {
                basicInfoSection
                administratorSection
                financialSection
                detailsSection
                saveButton
                if propertyId != nil {
                    deleteSection
                }
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
            viewModel.loadAdministrators()
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
        .alert("properties.delete.title",
            isPresented: $showDeleteConfirmation
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                deleteProperty()
            }
        } message: {
            Text("properties.delete.confirmation.message")
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

            TextField(
                "properties.cadastral_reference",
                text: $viewModel.cadastralReference
            )
            .autocapitalization(.none)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)

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

    private var administratorSection: some View {
        Section("properties.administrator") {
            Picker(
                "properties.administrator.select",
                selection: $viewModel.administratorId
            ) {
                Text("properties.administrator.none")
                    .tag(nil as String?)

                ForEach(viewModel.administrators) { admin in
                    Text(admin.name).tag(admin.id as String?)
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

    private var deleteSection: some View {
        Section {
            DeleteButton(title: "properties.delete.title") {
                showDeleteConfirmation = true
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private func deleteProperty() {
        guard let propertyId else { return }
        Task {
            do {
                try await firestoreService.delete(id: propertyId, from: "properties")
                if let onDeleted {
                    onDeleted()
                } else {
                    dismiss()
                }
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
