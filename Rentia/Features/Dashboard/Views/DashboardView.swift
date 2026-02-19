import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @AppStorage("defaultCurrency") private var defaultCurrency = "EUR"

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                headerSection

                statsGrid

                recentActivitySection
            }
            .padding(AppSpacing.medium)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("tabs.dashboard")
        .refreshable { viewModel.loadData() }
        .onAppear { viewModel.loadData() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("dashboard.bienvenido")
                .font(AppTypography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text("dashboard.resumen_de_tus_propiedades")
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
                title: "dashboard.ingresos_mensuales",
                value: viewModel.totalMonthlyIncome
                    .formatted(.currency(code: defaultCurrency)),
                icon: "dollarsign.circle.fill",
                color: AppTheme.Colors.success
            )

            StatCard(
                title: "dashboard.pagos_pendientes",
                value: "\(viewModel.pendingPaymentsCount)",
                icon: "clock.fill",
                color: AppTheme.Colors.warning
            )

            StatCard(
                title: "dashboard.ocupacion",
                value: String(
                    format: "%.0f%%",
                    viewModel.occupancyRate
                ),
                icon: "chart.pie.fill",
                color: AppTheme.Colors.secondary
            )

            StatCard(
                title: "dashboard.inquilinos_activos",
                value: "\(viewModel.activeTenants)",
                icon: "person.2.fill",
                color: AppTheme.Colors.primary
            )
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("dashboard.actividad_reciente")
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
}
