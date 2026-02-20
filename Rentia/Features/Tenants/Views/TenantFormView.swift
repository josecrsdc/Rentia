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
                saveButton
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(
            tenantId != nil
                ? "tenants.edit.title"
                : "tenants.new.title"
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
        Section("tenants.personal_information") {
            TextField(
                "tenants.first_name",
                text: $viewModel.firstName
            )

            TextField(
                "tenants.last_name",
                text: $viewModel.lastName
            )

            TextField(
                "tenants.id_number",
                text: $viewModel.idNumber
            )

            Picker("properties.status",
                selection: $viewModel.status
            ) {
                ForEach(TenantStatus.allCases, id: \.self) { status in
                    Text(status.localizedName).tag(status)
                }
            }
        }
    }

    private var contactSection: some View {
        Section("tenants.contact") {
            TextField(
                "tenants.email",
                text: $viewModel.email
            )
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()

            TextField(
                "tenants.phone",
                text: $viewModel.phone
            )
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
        }
    }

    private var propertiesSection: some View {
        Section {
            if viewModel.availableProperties.isEmpty {
                Text("tenants.no_properties_registered")
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
                    "tenants.select_properties_helper"
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

    private var saveButton: some View {
        Section {
            PrimaryButton(
                title: viewModel.isEditing
                    ? "common.save_changes"
                    : "tenants.add",
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
