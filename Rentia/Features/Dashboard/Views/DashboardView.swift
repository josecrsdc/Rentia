import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

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
        .navigationTitle(String(localized: "Inicio"))
        .refreshable { viewModel.loadData() }
        .onAppear { viewModel.loadData() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(String(localized: "Bienvenido"))
                .font(AppTypography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(String(localized: "Resumen de tus propiedades"))
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
                title: String(localized: "Ingresos Mensuales"),
                value: viewModel.totalMonthlyIncome
                    .formatted(.currency(code: "USD")),
                icon: "dollarsign.circle.fill",
                color: AppTheme.Colors.success
            )

            StatCard(
                title: String(localized: "Pagos Pendientes"),
                value: "\(viewModel.pendingPaymentsCount)",
                icon: "clock.fill",
                color: AppTheme.Colors.warning
            )

            StatCard(
                title: String(localized: "Ocupacion"),
                value: String(
                    format: "%.0f%%",
                    viewModel.occupancyRate
                ),
                icon: "chart.pie.fill",
                color: AppTheme.Colors.secondary
            )

            StatCard(
                title: String(localized: "Inquilinos Activos"),
                value: "\(viewModel.activeTenants)",
                icon: "person.2.fill",
                color: AppTheme.Colors.primary
            )
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Actividad Reciente"))
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            if viewModel.recentPayments.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: String(localized: "Sin actividad reciente"),
                    message: String(
                        localized: "Los pagos recientes apareceran aqui"
                    )
                )
            } else {
                ForEach(viewModel.recentPayments) { payment in
                    PaymentCard(payment: payment)
                }
            }
        }
    }
}
