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
                ? "properties.edit.title"
                : "properties.new.title"
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
        Section("properties.basic_information") {
            TextField(
                "properties.name",
                text: $viewModel.name
            )

            TextField(
                "properties.address",
                text: $viewModel.address
            )

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

    private var tenantSection: some View {
        Section {
            if viewModel.tenants.isEmpty {
                VStack(spacing: AppSpacing.medium) {
                    Text("properties.no_tenants_registered")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    Button {
                        viewModel.showCreateTenant = true
                    } label: {
                        Label(
                            "properties.create_tenant",
                            systemImage: "person.badge.plus"
                        )
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.small)
            } else {
                Picker("properties.tenant",
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
                        "properties.create_new_tenant",
                        systemImage: "person.badge.plus"
                    )
                    .font(AppTypography.caption)
                }
            }
        } header: {
            Text("properties.tenant")
        } footer: {
            Text(
                "properties.select_tenant_helper"
            )
        }
    }

    private var financialSection: some View {
        Section("properties.financial_information") {
            TextField(
                "properties.monthly_rent",
                text: $viewModel.monthlyRent
            )
            .keyboardType(.decimalPad)

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
