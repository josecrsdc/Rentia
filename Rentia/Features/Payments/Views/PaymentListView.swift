import SwiftUI

struct PaymentListView: View {
    @State private var viewModel = PaymentListViewModel()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.payments.isEmpty {
                ProgressView()
            } else if viewModel.payments.isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: String(localized: "Sin pagos"),
                    message: String(
                        localized: "Los pagos registrados apareceran aqui"
                    ),
                    actionTitle: String(localized: "Registrar Pago"),
                    action: {}
                )
            } else {
                paymentList
            }
        }
        .navigationTitle(String(localized: "Pagos"))
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
                PaymentFormView(paymentId: id)
            }
        }
        .refreshable { viewModel.loadPayments() }
        .onAppear { viewModel.loadPayments() }
        .alert(
            String(localized: "Error"),
            isPresented: $viewModel.showError
        ) {
            Button(String(localized: "Aceptar"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
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
                    title: String(localized: "Todos"),
                    isSelected: viewModel.selectedFilter == nil
                ) {
                    viewModel.selectedFilter = nil
                }

                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    filterChip(
                        title: status.displayName,
                        isSelected: viewModel.selectedFilter == status
                    ) {
                        viewModel.selectedFilter = status
                    }
                }
            }
        }
    }

    private func filterChip(
        title: String,
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
