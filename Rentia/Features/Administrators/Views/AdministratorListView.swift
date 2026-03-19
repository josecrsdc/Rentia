import SwiftUI

struct AdministratorListView: View {
    @State private var viewModel = AdministratorListViewModel()
    @State private var showCreateAdministrator = false

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.administrators.isEmpty {
                ProgressView()
            } else if viewModel.administrators.isEmpty {
                EmptyStateView(
                    icon: "person.badge.key",
                    title: "administrators.empty.title",
                    message: "administrators.empty.message",
                    actionTitle: "administrators.add",
                    action: { showCreateAdministrator = true }
                )
            } else {
                administratorList
            }
        }
        .navigationTitle("administrators.title")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AdministratorDestination.form(nil)) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: AdministratorDestination.self) { destination in
            switch destination {
            case .detail(let id):
                AdministratorDetailView(administratorId: id)
            case .form(let id):
                AdministratorFormView(administratorId: id)
            case .list:
                EmptyView()
            }
        }
        .navigationDestination(isPresented: $showCreateAdministrator) {
            AdministratorFormView(administratorId: nil)
        }
        .refreshable { viewModel.loadAdministrators() }
        .onAppear { viewModel.loadAdministrators() }
        .alert("common.error",
            isPresented: $viewModel.showError
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var administratorList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                SearchBar(
                    text: $viewModel.searchText,
                    placeholder: "common.search"
                )

                ForEach(viewModel.filteredAdministrators) { administrator in
                    NavigationLink(
                        value: AdministratorDestination.detail(administrator.id ?? "")
                    ) {
                        AdministratorCard(administrator: administrator)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.medium)
        }
    }
}
