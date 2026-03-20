import SwiftUI

struct AnnualReportView: View {
    @State private var viewModel = AnnualReportViewModel()
    @AppStorage("defaultCurrency") private var defaultCurrency = "EUR"
    @State private var showShareSheet = false
    @State private var csvData: String = ""

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else {
                reportContent
            }
        }
        .navigationTitle("reports.annual")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    csvData = viewModel.exportCSV()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(Text("reports.export.csv"))
            }
        }
        .task { viewModel.loadData() }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [csvData])
        }
    }

    private var reportContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                yearPicker
                summaryCard
                monthlyBreakdown
            }
            .padding(AppSpacing.medium)
        }
    }

    private var yearPicker: some View {
        Picker("reports.year", selection: $viewModel.selectedYear) {
            ForEach(viewModel.availableYears, id: \.self) { year in
                Text(String(year)).tag(year)
            }
        }
        .pickerStyle(.segmented)
        // No onChange needed — computed properties observe selectedYear automatically
    }

    private var summaryCard: some View {
        VStack(spacing: AppSpacing.medium) {
            Text("reports.total_annual")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Text(viewModel.annualTotal.formatted(.currency(code: defaultCurrency)))
                .font(AppTypography.moneyLarge)
                .foregroundStyle(AppTheme.Colors.success)
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

    private var monthlyBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("reports.monthly_breakdown")
                .font(AppTypography.title3)

            ForEach(Array(monthAbbreviations.enumerated()), id: \.offset) { index, month in
                monthRow(month: month, amount: viewModel.monthlyTotals[safe: index] ?? 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var monthAbbreviations: [String] {
        (1...12).map { month in
            let date = Calendar.current.date(
                from: DateComponents(year: viewModel.selectedYear, month: month, day: 1)
            ) ?? Date()
            return date.formatted(.dateTime.month(.abbreviated))
        }
    }

    private func monthRow(month: String, amount: Double) -> some View {
        let maxAmount = viewModel.monthlyTotals.max() ?? 1

        return HStack {
            Text(month)
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 40, alignment: .leading)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppTheme.Colors.success.opacity(0.1))
                    .frame(maxWidth: .infinity, minHeight: 24, maxHeight: 24)

                GeometryReader { proxy in
                    let width = maxAmount > 0
                        ? (amount / maxAmount) * proxy.size.width
                        : 0

                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(AppTheme.Colors.success.opacity(0.5))
                        .frame(width: max(width, 0), height: 24)
                }
                .frame(height: 24)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            Text(amount.formatted(.currency(code: defaultCurrency)))
                .font(AppTypography.headline)
                .frame(width: 100, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(month): \(amount.formatted(.currency(code: defaultCurrency)))")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
