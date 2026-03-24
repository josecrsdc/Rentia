import SwiftUI

struct ExpenseDetailView: View {
    let expenseId: String
    @State private var expense: Expense?
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage: String?
    @State private var showEditForm = false
    @Environment(\.dismiss)
    private var dismiss

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let expense {
                expenseContent(expense)
            }
        }
        .navigationTitle("expenses.detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("common.edit") { showEditForm = true }
            }
        }
        .task { loadExpense() }
        .sheet(isPresented: $showEditForm, onDismiss: { loadExpense() }) {
            if let expense {
                NavigationStack {
                    ExpenseFormView(
                        propertyId: expense.propertyId,
                        expenseId: expenseId
                    )
                }
            }
        }
        .alert("expenses.delete.title", isPresented: $showDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) { deleteExpense() }
        } message: {
            Text("expenses.delete.confirmation.message")
        }
        .alert("common.error", isPresented: $showDeleteError) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    private func expenseContent(_ expense: Expense) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                amountCard(expense)
                detailsCard(expense)
                deleteButton
            }
            .padding(AppSpacing.medium)
        }
    }

    private func amountCard(_ expense: Expense) -> some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: expense.category.icon)
                .font(.largeTitle)
                .foregroundStyle(AppTheme.Colors.error)
                .frame(width: 64, height: 64)
                .background(AppTheme.Colors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

            Text(expense.amount.formatted(.currency(code: "EUR")))
                .font(AppTypography.moneyLarge)
                .foregroundStyle(AppTheme.Colors.error)

            Text(expense.category.localizedName)
                .font(AppTypography.headline)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(AppTheme.Colors.error.opacity(0.1))
                .foregroundStyle(AppTheme.Colors.error)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.extraLarge)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(
            color: AppTheme.Shadows.card,
            radius: AppTheme.Shadows.cardRadius,
            x: AppTheme.Shadows.cardX,
            y: AppTheme.Shadows.cardY
        )
    }

    private func detailsCard(_ expense: Expense) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("expenses.details")
                .font(AppTypography.title3)

            detailRow(
                icon: "calendar",
                label: "expenses.date",
                value: expense.date.mediumFormatted
            )

            detailRow(
                icon: "text.alignleft",
                label: "expenses.description",
                value: expense.description
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func detailRow(icon: String, label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(AppTypography.headline)
                .multilineTextAlignment(.trailing)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("expenses.delete.title")
            }
            .font(AppTypography.body)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.medium)
            .background(AppTheme.Colors.error.opacity(0.1))
            .foregroundStyle(AppTheme.Colors.error)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        }
    }

    private func loadExpense() {
        isLoading = true
        Task {
            expense = try? await firestoreService.read(id: expenseId, from: "expenses")
            isLoading = false
        }
    }

    private func deleteExpense() {
        Task {
            do {
                try await firestoreService.delete(id: expenseId, from: "expenses")
                dismiss()
            } catch {
                deleteErrorMessage = error.localizedDescription
                showDeleteError = true
            }
        }
    }
}
