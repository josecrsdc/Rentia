import SwiftUI

struct ExpenseListView: View {
    let propertyId: String
    @State private var viewModel: ExpenseListViewModel
    @State private var showAddForm = false
    @State private var expenseToEdit: Expense?

    init(propertyId: String) {
        self.propertyId = propertyId
        _viewModel = State(initialValue: ExpenseListViewModel(propertyId: propertyId))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.expenses.isEmpty {
                ProgressView()
            } else {
                expensesList
            }
        }
        .navigationTitle("expenses.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { viewModel.loadExpenses() }
        .sheet(isPresented: $showAddForm, onDismiss: { viewModel.loadExpenses() }) {
            NavigationStack {
                ExpenseFormView(propertyId: propertyId)
            }
        }
        .sheet(item: $expenseToEdit, onDismiss: { viewModel.loadExpenses() }) { expense in
            NavigationStack {
                ExpenseFormView(propertyId: propertyId, expenseId: expense.id)
            }
        }
        .alert("common.error", isPresented: $viewModel.showError) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var expensesList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                filterSection
                totalCard

                if viewModel.filteredExpenses.isEmpty {
                    EmptyStateView(
                        icon: "eurosign.circle",
                        title: "expenses.empty",
                        message: "expenses.empty.hint"
                    )
                    .padding(.top, AppSpacing.xxxLarge)
                } else {
                    ForEach(viewModel.filteredExpenses) { expense in
                        NavigationLink(value: ExpenseDestination.detail(expense.id ?? "")) {
                            expenseRow(expense)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.delete(expense: expense)
                            } label: {
                                Label("common.delete", systemImage: "trash")
                            }

                            Button {
                                expenseToEdit = expense
                            } label: {
                                Label("common.edit", systemImage: "pencil")
                            }
                            .tint(AppTheme.Colors.primary)
                        }
                    }
                }
            }
            .padding(AppSpacing.medium)
        }
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                filterChip(nil)

                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    filterChip(category)
                }
            }
        }
    }

    private func filterChip(_ category: ExpenseCategory?) -> some View {
        let isSelected = viewModel.selectedCategory == category
        let text: LocalizedStringKey = category?.localizedName ?? "expenses.filter.all"

        return Button {
            viewModel.selectedCategory = category
        } label: {
            Text(text)
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.cardBackground)
                .foregroundStyle(isSelected ? Color.white : AppTheme.Colors.textSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var totalCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text("expenses.total")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Text(viewModel.totalAmount.formatted(.currency(code: "EUR")))
                    .font(AppTypography.moneyMedium)
                    .foregroundStyle(AppTheme.Colors.error)
            }

            Spacer()

            Text("\(viewModel.filteredExpenses.count)")
                .font(AppTypography.title2)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: expense.category.icon)
                .font(.title3)
                .foregroundStyle(AppTheme.Colors.error)
                .frame(width: 44, height: 44)
                .background(AppTheme.Colors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(expense.description)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(expense.date.shortFormatted)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.extraSmall) {
                Text(expense.amount.formatted(.currency(code: "EUR")))
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.Colors.error)

                Text(expense.category.localizedName)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textLight)
        }
        .cardStyle()
    }
}
