import SwiftUI

struct TenantListView: View {
    @State private var viewModel = TenantListViewModel()
    @State private var showCreateTenant = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.tenants.isEmpty {
                ProgressView()
            } else if viewModel.tenants.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "tenants.empty.title",
                    message: "tenants.empty.message",
                    actionTitle: "tenants.add",
                    action: { showCreateTenant = true }
                )
            } else {
                tenantList
            }
        }
        .navigationTitle("tabs.tenants")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: TenantDestination.form(nil)) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: TenantDestination.self) { destination in
            switch destination {
            case .detail(let id):
                TenantDetailView(tenantId: id)
            case .form(let id):
                TenantFormView(
                    tenantId: id,
                    onDeleted: { path.removeLast(min(2, path.count)) }
                )
            }
        }
        .navigationDestination(isPresented: $showCreateTenant) {
            TenantFormView(tenantId: nil)
        }
        .navigationDestination(for: PaymentDestination.self) { destination in
            switch destination {
            case .detail(let id):
                PaymentDetailView(paymentId: id)
            case .form(let id):
                PaymentFormView(
                    paymentId: id,
                    onDeleted: { path.removeLast(min(2, path.count)) }
                )
            }
        }
        .navigationDestination(for: LeaseDestination.self) { destination in
            switch destination {
            case .detail(let id):
                LeaseDetailView(leaseId: id)
            case .form(let id):
                LeaseFormView(
                    leaseId: id,
                    onDeleted: { path.removeLast(min(2, path.count)) }
                )
            case .formForProperty(let propertyId):
                LeaseFormView(leaseId: nil, propertyId: propertyId)
            }
        }
        .refreshable { viewModel.loadTenants() }
        .onAppear { viewModel.loadTenants() }
        .alert("common.error",
            isPresented: $viewModel.showError
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        }
    }

    private var tenantList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                SearchBar(
                    text: $viewModel.searchText,
                    placeholder: "tenants.search"
                )

                ForEach(viewModel.filteredTenants) { tenant in
                    NavigationLink(
                        value: TenantDestination.detail(tenant.id ?? "")
                    ) {
                        TenantCard(tenant: tenant)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.medium)
        }
    }
}
