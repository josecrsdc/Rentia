import SwiftUI

struct DebtReportView: View {
    @State private var viewModel = DebtReportViewModel()
    @AppStorage("defaultCurrency")
    private var defaultCurrency = "EUR"

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else {
                debtContent
            }
        }
        .navigationTitle("reports.debt")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadData() }
        .refreshable { viewModel.loadData() }
    }

    private var debtContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                totalDebtCard
                debtList
            }
            .padding(AppSpacing.medium)
        }
    }

    private var totalDebtCard: some View {
        VStack(spacing: AppSpacing.medium) {
            Text("reports.total_debt")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Text(viewModel.totalDebt.formatted(.currency(code: defaultCurrency)))
                .font(AppTypography.moneyLarge)
                .foregroundStyle(viewModel.totalDebt > 0 ? AppTheme.Colors.error : AppTheme.Colors.success)
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

    private var debtList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("reports.debtors")
                .font(AppTypography.title3)

            if viewModel.tenantsWithDebt.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(AppTheme.Colors.success)

                    Text("reports.no_debt")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            } else {
                ForEach(viewModel.tenantsWithDebt) { debtInfo in
                    debtRow(debtInfo)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func debtRow(_ debtInfo: TenantDebt) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Text(tenantInitials(debtInfo.tenant))
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(AppTheme.Colors.error)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(debtInfo.tenant.fullName)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                HStack(spacing: AppSpacing.small) {
                    if debtInfo.overdueCount > 0 {
                        Label("\(debtInfo.overdueCount)", systemImage: "exclamationmark.circle")
                            .font(AppTypography.caption2)
                            .foregroundStyle(AppTheme.Colors.error)
                    }

                    if debtInfo.pendingCount > 0 {
                        Label("\(debtInfo.pendingCount)", systemImage: "clock")
                            .font(AppTypography.caption2)
                            .foregroundStyle(AppTheme.Colors.warning)
                    }
                }
            }

            Spacer()

            Text(debtInfo.totalDebt.formatted(.currency(code: defaultCurrency)))
                .font(AppTypography.headline)
                .foregroundStyle(AppTheme.Colors.error)
        }
    }

    private func tenantInitials(_ tenant: Tenant) -> String {
        let first = tenant.firstName.prefix(1).uppercased()
        let last = tenant.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }
}
