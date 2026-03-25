import SwiftUI

struct PaymentListView: View {
    @State private var viewModel = PaymentListViewModel()
    @State private var showCreatePayment = false
    @State private var path = NavigationPath()
    @State private var showStatusDialog = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.payments.isEmpty {
                    ProgressView()
                } else if viewModel.payments.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "payments.empty.title",
                        message: "payments.empty.message",
                        actionTitle: "payments.record",
                        action: { showCreatePayment = true }
                    )
                } else {
                    paymentList
                }
            }
            .navigationTitle("tabs.payments")
            .toolbar { toolbarContent }
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
            .navigationDestination(isPresented: $showCreatePayment) {
                PaymentFormView(paymentId: nil)
            }
            .refreshable { viewModel.loadPayments() }
            .onAppear { viewModel.loadPayments() }
            .alert("common.error", isPresented: $viewModel.showError) {
                Button("common.accept", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .confirmationDialog(
                String(localized: "payments.change_status"),
                isPresented: $showStatusDialog,
                titleVisibility: .visible
            ) {
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Button {
                        viewModel.updateStatusForSelected(to: status)
                    } label: {
                        Text(status.localizedName)
                    }
                }
                Button(String(localized: "common.cancel"), role: .cancel) {}
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            leadingToolbarItems
        }
        ToolbarItem(placement: .primaryAction) {
            if viewModel.isSelecting {
                selectingTrailingItems
            } else {
                NavigationLink(value: PaymentDestination.form(nil)) {
                    Image(systemName: "plus")
                        .accessibilityLabel(String(localized: "payments.record"))
                }
            }
        }
    }

    private var selectingTrailingItems: some View {
        HStack(spacing: AppSpacing.small) {
            if !viewModel.selectedPaymentIds.isEmpty {
                Button {
                    showStatusDialog = true
                } label: {
                    Text("payments.change_status")
                        .font(AppTypography.body)
                }
                .accessibilityLabel(String(localized: "payments.change_status"))
            }
            Button {
                viewModel.isSelecting = false
                viewModel.selectedPaymentIds = []
            } label: {
                Text("common.cancel")
            }
            .accessibilityLabel(String(localized: "common.cancel"))
        }
    }

    private var leadingToolbarItems: some View {
        HStack(spacing: AppSpacing.small) {
            propertyFilterMenu
            if !viewModel.isSelecting {
                Button {
                    viewModel.isSelecting = true
                } label: {
                    Text("payments.select")
                }
                .accessibilityLabel(String(localized: "payments.select"))
            }
        }
    }

    private var propertyFilterMenu: some View {
        Menu {
            Button {
                viewModel.selectedPropertyIds = []
            } label: {
                HStack {
                    Text("payments.filter.all_properties")
                    if viewModel.selectedPropertyIds.isEmpty {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Divider()
            ForEach(viewModel.properties) { property in
                Button {
                    togglePropertyFilter(property)
                } label: {
                    HStack {
                        Text(property.name)
                        if let id = property.id, viewModel.selectedPropertyIds.contains(id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("payments.filter.property", systemImage: "line.3.horizontal.decrease.circle")
                .foregroundStyle(
                    viewModel.selectedPropertyIds.isEmpty
                        ? AppTheme.Colors.textSecondary
                        : AppTheme.Colors.primary
                )
                .accessibilityLabel(String(localized: "payments.filter.property"))
        }
    }

    private func togglePropertyFilter(_ property: Property) {
        guard let id = property.id else { return }
        if viewModel.selectedPropertyIds.contains(id) {
            viewModel.selectedPropertyIds.remove(id)
        } else {
            viewModel.selectedPropertyIds.insert(id)
        }
    }

    private var paymentList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                filterChips

                if viewModel.isSelecting && !viewModel.selectedPaymentIds.isEmpty {
                    Text("\(viewModel.selectedPaymentIds.count) \(String(localized: "payments.selected_count"))")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(viewModel.filteredPayments) { payment in
                    paymentRow(payment)
                }
            }
            .padding(AppSpacing.medium)
        }
    }

    @ViewBuilder
    private func paymentRow(_ payment: Payment) -> some View {
        if viewModel.isSelecting {
            Button {
                viewModel.togglePaymentSelection(payment)
            } label: {
                HStack(spacing: AppSpacing.medium) {
                    selectionCircle(for: payment)
                    PaymentCard(payment: payment)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selectionAccessibilityLabel(for: payment))
        } else {
            NavigationLink(value: PaymentDestination.detail(payment.id ?? "")) {
                PaymentCard(payment: payment)
            }
            .buttonStyle(.plain)
        }
    }

    private func selectionCircle(for payment: Payment) -> some View {
        let isSelected = payment.id.map { viewModel.selectedPaymentIds.contains($0) } ?? false
        return Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundStyle(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
            .accessibilityHidden(true)
    }

    private func selectionAccessibilityLabel(for payment: Payment) -> String {
        let isSelected = payment.id.map { viewModel.selectedPaymentIds.contains($0) } ?? false
        return isSelected
            ? String(localized: "common.deselect")
            : String(localized: "common.select")
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                filterChip(title: "payments.all", isSelected: viewModel.selectedFilter == nil) {
                    viewModel.selectedFilter = nil
                }
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    filterChip(
                        title: status.localizedName,
                        isSelected: viewModel.selectedFilter == status
                    ) {
                        viewModel.selectedFilter = status
                    }
                }
            }
        }
    }

    private func filterChip(
        title: LocalizedStringKey,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.cardBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
