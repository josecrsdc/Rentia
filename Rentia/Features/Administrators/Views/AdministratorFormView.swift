import SwiftUI

struct AdministratorFormView: View {
    let administratorId: String?
    @State private var viewModel = AdministratorFormViewModel()
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss)
    private var dismiss

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            Form {
                personalInfoSection
                contactSection
                saveButton
                if administratorId != nil {
                    deleteSection
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(
            administratorId != nil
                ? "administrators.edit.title"
                : "administrators.new.title"
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let administratorId {
                viewModel.loadAdministrator(id: administratorId)
            }
        }
        .onChange(of: viewModel.didSave) {
            if viewModel.didSave {
                dismiss()
            }
        }
        .alert("common.error",
            isPresented: $viewModel.showError
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("administrators.delete.title",
            isPresented: $showDeleteConfirmation
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                deleteAdministrator()
            }
        } message: {
            Text("administrators.delete.confirmation.message")
        }
    }

    // MARK: - Sections

    private var personalInfoSection: some View {
        Section("administrators.name") {
            TextField(
                "administrators.name",
                text: $viewModel.name
            )
        }
    }

    private var contactSection: some View {
        Section("tenants.contact") {
            TextField(
                "administrators.phone",
                text: $viewModel.phone
            )
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)

            TextField(
                "administrators.landline_phone",
                text: $viewModel.landlinePhone
            )
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)

            TextField(
                "administrators.email",
                text: $viewModel.email
            )
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
        }
    }

    private var deleteSection: some View {
        Section {
            DeleteButton(title: "administrators.delete.title") {
                showDeleteConfirmation = true
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private func deleteAdministrator() {
        guard let administratorId else { return }
        Task {
            do {
                try await firestoreService.delete(id: administratorId, from: "administrators")
                dismiss()
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
                    : "administrators.add",
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
