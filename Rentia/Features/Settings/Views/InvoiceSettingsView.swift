import PhotosUI
import SwiftUI

struct InvoiceSettingsView: View {
    @State private var viewModel = InvoiceSettingsViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else {
                Form {
                    logoSection
                    issuerSection
                    contactSection
                    bankSection
                    invoiceCounterSection
                    saveSection
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("settings.invoice.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
        .onChange(of: selectedPhoto) { _, item in
            loadSelectedPhoto(item)
        }
        .onChange(of: viewModel.didSave) {
            if viewModel.didSave { dismiss() }
        }
        .alert("common.error", isPresented: $viewModel.showError) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        Section("settings.invoice.logo") {
            HStack {
                Spacer()
                VStack(spacing: AppSpacing.small) {
                    if let image = viewModel.pendingLogoImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    } else if let urlString = viewModel.logoURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            logoPlaceholder
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    } else {
                        logoPlaceholder
                    }

                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        Text(viewModel.logoURL == nil && viewModel.pendingLogoImage == nil
                            ? "settings.invoice.logo.add"
                            : "settings.invoice.logo.change"
                        )
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.primary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, AppSpacing.small)
        }
    }

    private var logoPlaceholder: some View {
        Image(systemName: "building.2")
            .font(.system(size: 32))
            .foregroundStyle(AppTheme.Colors.textLight)
            .frame(width: 80, height: 80)
            .background(AppTheme.Colors.primary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
    }

    // MARK: - Issuer

    private var issuerSection: some View {
        Section("settings.invoice.issuer") {
            TextField("settings.invoice.display_name", text: $viewModel.displayName)
                .textContentType(.organizationName)
            TextField("settings.invoice.tax_id", text: $viewModel.taxId)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            TextField("settings.invoice.address", text: $viewModel.address, axis: .vertical)
                .lineLimit(2...4)
                .textContentType(.fullStreetAddress)
        }
    }

    // MARK: - Contact

    private var contactSection: some View {
        Section("settings.invoice.contact") {
            TextField("settings.invoice.phone", text: $viewModel.phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
            TextField("settings.invoice.email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
        }
    }

    // MARK: - Bank

    private var bankSection: some View {
        Section("settings.invoice.bank") {
            TextField("settings.invoice.bank_account", text: $viewModel.bankAccount)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .font(.system(.body, design: .monospaced))
        }
    }

    // MARK: - Invoice Counter

    private var invoiceCounterSection: some View {
        Section {
            Stepper(
                value: $viewModel.invoiceCounter,
                in: 1...99999
            ) {
                HStack {
                    Text("settings.invoice.counter")
                    Spacer()
                    Text("\(viewModel.invoiceCounter)")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        } footer: {
            Text("settings.invoice.counter.hint")
                .font(AppTypography.caption)
        }
    }

    // MARK: - Save

    private var saveSection: some View {
        Section {
            PrimaryButton(
                title: "common.save_changes",
                isLoading: viewModel.isSaving
            ) {
                viewModel.save()
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Helpers

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.pendingLogoImage = image
            }
        }
    }
}
