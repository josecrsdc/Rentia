import SwiftUI

struct ProfitabilityView: View {
    let propertyId: String
    let propertyName: String
    @State private var viewModel: ProfitabilityViewModel
    @AppStorage("defaultCurrency")
    private var defaultCurrency = "EUR"

    init(propertyId: String, propertyName: String) {
        self.propertyId = propertyId
        self.propertyName = propertyName
        _viewModel = State(initialValue: ProfitabilityViewModel(propertyId: propertyId))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else {
                profitabilityContent
            }
        }
        .navigationTitle("reports.profitability")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.loadData() }
    }

    private var profitabilityContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                periodPicker
                resultCard
                breakdownCard
            }
            .padding(AppSpacing.medium)
        }
    }

    private var periodPicker: some View {
        Picker("reports.period", selection: $viewModel.selectedPeriod) {
            ForEach(ReportPeriod.allCases, id: \.self) { period in
                Text(period.localizedName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        // No onChange needed — computed properties observe selectedPeriod automatically
    }

    private var resultCard: some View {
        VStack(spacing: AppSpacing.medium) {
            Text("reports.result")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Text(viewModel.result.formatted(.currency(code: defaultCurrency)))
                .font(AppTypography.moneyLarge)
                .foregroundStyle(viewModel.resultIsPositive
                    ? AppTheme.Colors.success : AppTheme.Colors.error)

            Text(viewModel.resultIsPositive ? "reports.profitable" : "reports.loss")
                .font(AppTypography.caption)
                .foregroundStyle(viewModel.resultIsPositive
                    ? AppTheme.Colors.success : AppTheme.Colors.error)
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
        .accessibilityElement(children: .combine)
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("reports.breakdown")
                .font(AppTypography.title3)

            incomeRow
            Divider()
            expensesRow
            Divider()
            resultRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var incomeRow: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(AppTheme.Colors.success)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text("reports.income")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()

            Text(viewModel.totalIncome.formatted(.currency(code: defaultCurrency)))
                .font(AppTypography.headline)
                .foregroundStyle(AppTheme.Colors.success)
        }
        .accessibilityElement(children: .combine)
    }

    private var expensesRow: some View {
        HStack {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundStyle(AppTheme.Colors.error)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text("reports.expenses")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()

            Text(viewModel.totalExpenses.formatted(.currency(code: defaultCurrency)))
                .font(AppTypography.headline)
                .foregroundStyle(AppTheme.Colors.error)
        }
        .accessibilityElement(children: .combine)
    }

    private var resultRow: some View {
        HStack {
            Image(systemName: "equal.circle.fill")
                .foregroundStyle(viewModel.resultIsPositive
                    ? AppTheme.Colors.success : AppTheme.Colors.error)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text("reports.result")
                .font(AppTypography.headline)

            Spacer()

            Text(viewModel.result.formatted(.currency(code: defaultCurrency)))
                .font(AppTypography.moneyMedium)
                .foregroundStyle(viewModel.resultIsPositive
                    ? AppTheme.Colors.success : AppTheme.Colors.error)
        }
        .accessibilityElement(children: .combine)
    }
}
