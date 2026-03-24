import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @AppStorage("defaultCurrency")
    private var defaultCurrency = "EUR"

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                headerSection

                statsGrid

                reportsSection

                recentActivitySection
            }
            .padding(AppSpacing.medium)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("tabs.dashboard")
        .refreshable { viewModel.loadData() }
        .onAppear { viewModel.loadData() }
        .navigationDestination(for: ReportDestination.self) { destination in
            switch destination {
            case .annual: AnnualReportView()
            case .debt: DebtReportView()
            case .profitability(let id, let name): ProfitabilityView(propertyId: id, propertyName: name)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("dashboard.welcome")
                .font(AppTypography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text("dashboard.properties_summary")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppSpacing.medium),
                GridItem(.flexible(), spacing: AppSpacing.medium),
            ],
            spacing: AppSpacing.medium
        ) {
            StatCard(
                title: "dashboard.monthly_income",
                value: viewModel.totalMonthlyIncome
                    .formatted(.currency(code: defaultCurrency)),
                icon: "dollarsign.circle.fill",
                color: AppTheme.Colors.success
            )

            StatCard(
                title: "dashboard.pending_payments",
                value: "\(viewModel.pendingPaymentsCount)",
                icon: "clock.fill",
                color: AppTheme.Colors.warning
            )

            StatCard(
                title: "dashboard.occupancy",
                value: String(
                    format: "%.0f%%",
                    viewModel.occupancyRate
                ),
                icon: "chart.pie.fill",
                color: AppTheme.Colors.secondary
            )

            StatCard(
                title: "dashboard.active_tenants",
                value: "\(viewModel.activeTenants)",
                icon: "person.2.fill",
                color: AppTheme.Colors.primary
            )
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("dashboard.recent_activity.title")
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            if viewModel.recentPayments.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "dashboard.recent_activity.empty.title",
                    message: "dashboard.empty_recent_payments"
                )
            } else {
                ForEach(viewModel.recentPayments) { payment in
                    PaymentCard(payment: payment)
                }
            }
        }
    }

    // MARK: - Reports Section

    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("reports.title")
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack(spacing: AppSpacing.medium) {
                reportButton(
                    title: "reports.annual",
                    icon: "chart.bar.fill",
                    color: AppTheme.Colors.primary,
                    destination: ReportDestination.annual
                )

                reportButton(
                    title: "reports.debt",
                    icon: "person.badge.minus",
                    color: AppTheme.Colors.error,
                    destination: ReportDestination.debt
                )
            }
        }
    }

    private func reportButton(
        title: LocalizedStringKey,
        icon: String,
        color: Color,
        destination: ReportDestination
    ) -> some View {
        NavigationLink(value: destination) {
            VStack(spacing: AppSpacing.small) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.medium)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }
}
