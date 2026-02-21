import SwiftUI

struct TenantFormView: View {
    let tenantId: String?
    var onSaved: ((String) -> Void)?
    @State private var viewModel = TenantFormViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Form {
                personalInfoSection
                contactSection
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
            if let tenantId {
                viewModel.loadTenant(id: tenantId)
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
