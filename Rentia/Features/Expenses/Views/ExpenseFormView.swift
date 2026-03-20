import SwiftUI

struct ExpenseFormView: View {
    let propertyId: String
    var expenseId: String?
    @State private var viewModel: ExpenseFormViewModel
    @Environment(\.dismiss) private var dismiss

    init(propertyId: String, expenseId: String? = nil) {
        self.propertyId = propertyId
        self.expenseId = expenseId
        _viewModel = State(initialValue: ExpenseFormViewModel(propertyId: propertyId))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            Form {
                amountSection
                categorySection
                descriptionSection
                dateSection
                saveButton
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(expenseId != nil ? "expenses.edit.title" : "expenses.new.title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isLoading)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
            }
        }
        .onAppear {
            if let expenseId {
                viewModel.loadExpense(id: expenseId)
            }
        }
        .onChange(of: viewModel.didSave) {
            if viewModel.didSave { dismiss() }
        }
        .alert("common.error", isPresented: $viewModel.showError) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var amountSection: some View {
        Section("expenses.amount") {
            HStack {
                Text("€")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                TextField("0.00", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
            }
        }
    }

    private var categorySection: some View {
        Section("expenses.category") {
            Picker("expenses.category", selection: $viewModel.category) {
                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    Label(category.localizedName, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private var descriptionSection: some View {
        Section("expenses.description") {
            TextField("expenses.description.placeholder", text: $viewModel.description)
        }
    }

    private var dateSection: some View {
        Section("expenses.date") {
            DatePicker(
                "expenses.date",
                selection: $viewModel.date,
                displayedComponents: .date
            )
            .labelsHidden()
        }
    }

    private var saveButton: some View {
        Section {
            Button {
                viewModel.save()
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("common.save")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
        }
    }
}
