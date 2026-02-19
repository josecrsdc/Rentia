import SwiftUI

struct PropertyListView: View {
    @State private var viewModel = PropertyListViewModel()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.properties.isEmpty {
                ProgressView()
            } else if viewModel.properties.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: String(localized: "Sin propiedades"),
                    message: String(
                        localized: "Agrega tu primera propiedad para comenzar"
                    ),
                    actionTitle: String(localized: "Agregar Propiedad"),
                    action: {}
                )
            } else {
                propertyList
            }
        }
        .navigationTitle(String(localized: "Propiedades"))
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
            }
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
        .alert(
            String(localized: "Error"),
            isPresented: $viewModel.showError
        ) {
            Button(String(localized: "Aceptar"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var propertyList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                SearchBar(
                    text: $viewModel.searchText,
                    placeholder: String(localized: "Buscar propiedades...")
                )

                ForEach(viewModel.filteredProperties) { property in
                    NavigationLink(
                        value: PropertyDestination.detail(property.id ?? "")
                    ) {
                        PropertyCard(property: property)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.medium)
        }
    }
}
