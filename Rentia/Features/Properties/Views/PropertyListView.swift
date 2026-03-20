import SwiftUI

struct PropertyListView: View {
    @State private var viewModel = PropertyListViewModel()
    @State private var showCreateProperty = false
    @State private var showMap = false

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
            } else if showMap {
                PropertyMapView(
                    properties: viewModel.properties,
                    leases: viewModel.leases
                )
            } else {
                propertyList
            }
        }
        .navigationTitle("tabs.properties")
        .toolbar {
            if !viewModel.properties.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation { showMap.toggle() }
                    } label: {
                        Image(systemName: showMap ? "list.bullet" : "map")
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: AppSpacing.small) {
                    NavigationLink(value: AdministratorDestination.list) {
                        Image(systemName: "person.badge.key")
                    }

                    Button {
                        showCreateProperty = true
                    } label: {
                        Image(systemName: "plus")
                    }
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
        .navigationDestination(for: AdministratorDestination.self) { destination in
            switch destination {
            case .list:
                AdministratorListView()
            case .detail(let id):
                AdministratorDetailView(administratorId: id)
            case .form(let id):
                AdministratorFormView(administratorId: id)
            }
        }
        .navigationDestination(for: LeaseDestination.self) { destination in
            switch destination {
            case .detail(let id):
                LeaseDetailView(leaseId: id)
            case .form(let id):
                LeaseFormView(leaseId: id)
            case .formForProperty(let propertyId):
                LeaseFormView(leaseId: nil, propertyId: propertyId)
            }
        }
        .navigationDestination(for: ExpenseDestination.self) { destination in
            switch destination {
            case .list(let id): ExpenseListView(propertyId: id)
            case .detail(let id): ExpenseDetailView(expenseId: id)
            }
        }
        .navigationDestination(for: ReportDestination.self) { destination in
            switch destination {
            case .annual: AnnualReportView()
            case .debt: DebtReportView()
            case .profitability(let id, let name): ProfitabilityView(propertyId: id, propertyName: name)
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
