import SwiftUI

struct PaymentListView: View {
    @State private var viewModel = PaymentListViewModel()
    @State private var showCreatePayment = false
    @State private var path = NavigationPath()

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: PaymentDestination.form(nil)) {
                    Image(systemName: "plus")
                }
            }
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
        .navigationDestination(isPresented: $showCreatePayment) {
            PaymentFormView(paymentId: nil)
        }
        .refreshable { viewModel.loadPayments() }
        .onAppear { viewModel.loadPayments() }
        .alert("common.error",
            isPresented: $viewModel.showError
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        }
    }

    private var paymentList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                filterChips

                ForEach(viewModel.filteredPayments) { payment in
                    NavigationLink(
                        value: PaymentDestination.detail(payment.id ?? "")
                    ) {
                        PaymentCard(payment: payment)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.medium)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                filterChip(
                    title: "payments.all",
                    isSelected: viewModel.selectedFilter == nil
                ) {
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
                .background(
                    isSelected
                        ? AppTheme.Colors.primary
                        : AppTheme.Colors.cardBackground
                )
                .foregroundStyle(
                    isSelected ? .white : AppTheme.Colors.textSecondary
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                                ? Color.clear
                                : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
    }
}
