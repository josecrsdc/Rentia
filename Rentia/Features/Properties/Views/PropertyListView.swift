import SwiftUI

struct PropertyListView: View {
    @State private var viewModel = PropertyListViewModel()
    @State private var showCreateProperty = false

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.properties.isEmpty {
                ProgressView()
            } else if viewModel.properties.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: "properties.empty.title",
                    message: "properties.empty.message",
                    actionTitle: "properties.add",
                    action: { showCreateProperty = true }
                )
            } else {
                propertyList
            }
        }
        .navigationTitle("tabs.properties")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: PropertyDestination.form(nil)) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: PropertyDestination.self) { destination in
            switch destination {
            case .detail(let id):
                PropertyDetailView(propertyId: id)
            case .form(let id):
                PropertyFormView(propertyId: id)
            case .payments(let propertyId):
                PropertyPaymentsView(propertyId: propertyId)
            }
        }
        .navigationDestination(isPresented: $showCreateProperty) {
            PropertyFormView(propertyId: nil)
        }
        .navigationDestination(for: TenantDestination.self) { destination in
            switch destination {
            case .detail(let id):
                TenantDetailView(tenantId: id)
            case .form(let id):
                TenantFormView(tenantId: id)
            }
        }
        .navigationDestination(for: PaymentDestination.self) { destination in
            switch destination {
            case .detail(let id):
                PaymentDetailView(paymentId: id)
            case .form(let id):
                PaymentFormView(paymentId: id)
            }
        }
        .refreshable { viewModel.loadProperties() }
        .onAppear { viewModel.loadProperties() }
        .alert("common.error",
            isPresented: $viewModel.showError
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var propertyList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                SearchBar(
                    text: $viewModel.searchText,
                    placeholder: "properties.search"
                )

                ForEach(viewModel.filteredProperties) { property in
                    NavigationLink(
                        value: PropertyDestination.detail(property.id ?? "")
                    ) {
                        PropertyCard(
                            property: property,
                            isRented: viewModel.isRented(property)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.medium)
        }
    }
}
