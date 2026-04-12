import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @AppStorage("defaultCurrency")
    private var defaultCurrency = "EUR"

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                periodHeader

                statsGrid

                reportsSection

                propertiesOverviewSection

                recentActivitySection
            }
            .padding(AppSpacing.medium)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("tabs.dashboard")
        .toolbar {
            ToolbarItem(placement: .principal) {
                periodToggle
            }
        }
        .refreshable { viewModel.loadData() }
        .onAppear { viewModel.loadData() }
        .animation(.easeInOut(duration: 0.2), value: viewModel.periodTitle)
        .navigationDestination(for: PropertyDestination.self) { destination in
            switch destination {
            case .detail(let id): PropertyDetailView(propertyId: id)
            case .form(let id): PropertyFormView(propertyId: id)
            case .payments(let id): PropertyPaymentsView(propertyId: id)
            }
        }
        .navigationDestination(for: ReportDestination.self) { destination in
            switch destination {
            case .annual: AnnualReportView()
            case .debt: DebtReportView()
            case .profitability(let id, let name): ProfitabilityView(propertyId: id, propertyName: name)
            }
        }
    }

    // MARK: - Period Header

    private var periodToggle: some View {
        Picker("", selection: Binding(
            get: { viewModel.isMonthMode ? 0 : 1 },
            set: { $0 == 0 ? viewModel.switchToMonthMode() : viewModel.switchToYearMode() }
        )) {
            Text("dashboard.period.month").tag(0)
            Text("dashboard.period.year").tag(1)
        }
        .pickerStyle(.segmented)
        .frame(width: 160)
    }

    private var periodHeader: some View {
        HStack(spacing: AppSpacing.large) {
            Button {
                viewModel.previousPeriod()
            } label: {
                Image(systemName: "chevron.left")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(Circle())
            }

            Text(viewModel.periodTitle)
                .font(AppTypography.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())

            Button {
                viewModel.nextPeriod()
            } label: {
                Image(systemName: "chevron.right")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(AppSpacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(
            color: AppTheme.Shadows.card,
            radius: AppTheme.Shadows.cardRadius,
            x: AppTheme.Shadows.cardX,
            y: AppTheme.Shadows.cardY
        )
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

    // MARK: - Properties Overview

    private var propertiesOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("tabs.properties")
                .font(AppTypography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            if viewModel.properties.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: "properties.empty.title",
                    message: "properties.empty.message"
                )
            } else {
                ForEach(viewModel.properties) { property in
                    NavigationLink(value: PropertyDestination.detail(property.id ?? "")) {
                        propertyRow(property)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func propertyRow(_ property: Property) -> some View {
        let activeLease = viewModel.leases.first {
            $0.propertyId == property.id && $0.status == .active
        }
        let activeTenant = activeLease.flatMap { lease in
            viewModel.tenants.first { $0.id == lease.tenantId }
        }
        let latestPayment = viewModel.payments
            .filter { $0.propertyId == property.id }
            .sorted { $0.dueDate > $1.dueDate }
            .first

        return HStack(spacing: AppSpacing.small) {
            Image(systemName: property.type.icon)
                .font(.title3)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(width: 40, height: 40)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

            VStack(alignment: .leading, spacing: 2) {
                Text(property.name)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                if let tenant = activeTenant {
                    Text(tenant.fullName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                } else {
                    Text("leases.no_active_contract")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textLight)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let payment = latestPayment {
                    paymentStatusBadge(payment.status)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textLight)
            }
        }
        .padding(AppSpacing.small)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }

    private func paymentStatusBadge(_ status: PaymentStatus) -> some View {
        let color: Color = switch status {
        case .paid: AppTheme.Colors.success
        case .pending: AppTheme.Colors.warning
        case .overdue: AppTheme.Colors.error
        case .partial: AppTheme.Colors.secondary
        case .cancelled: AppTheme.Colors.textLight
        }
        return Text(status.localizedName)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
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
