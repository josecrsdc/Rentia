import SwiftUI

struct WizardPaymentGenerationView: View {
    @Bindable var wizardViewModel: PropertyWizardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                summaryCard

                if let count = wizardViewModel.generatedPaymentCount {
                    successCard(count: count)
                } else if wizardViewModel.isGeneratingPayments {
                    loadingCard
                } else {
                    generatePrompt
                }

                if let error = wizardViewModel.paymentError {
                    errorCard(message: error)
                }
            }
            .padding(AppSpacing.medium)
        }
        .background(AppTheme.Colors.background)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("wizard.summary")
                .font(AppTypography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack {
                Image(systemName: "building.2")
                    .foregroundStyle(AppTheme.Colors.primary)
                Text(wizardViewModel.createdPropertyName ?? "")
                    .font(AppTypography.body)
            }

            HStack {
                Image(systemName: "person")
                    .foregroundStyle(AppTheme.Colors.primary)
                Text(wizardViewModel.createdTenantName ?? "")
                    .font(AppTypography.body)
            }

            if let lease = wizardViewModel.createdLease {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text(lease.startDate.shortFormatted)
                        .font(AppTypography.body)
                    if let endDate = lease.endDate {
                        Text("—")
                        Text(endDate.shortFormatted)
                            .font(AppTypography.body)
                    }
                }

                HStack {
                    Image(systemName: "banknote")
                        .foregroundStyle(AppTheme.Colors.primary)
                    Text(String(format: "%.2f", lease.rentAmount))
                        .font(AppTypography.moneySmall)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Generate Prompt

    private var generatePrompt: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.primary)

            Text("wizard.generate_payments_question")
                .font(AppTypography.title3)
                .multilineTextAlignment(.center)

            PrimaryButton(
                title: "wizard.generate_payments",
                isLoading: false
            ) {
                wizardViewModel.generatePayments()
            }

            Button("wizard.skip") {
                wizardViewModel.complete()
            }
            .font(AppTypography.body)
            .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .cardStyle()
    }

    // MARK: - Loading

    private var loadingCard: some View {
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
                .scaleEffect(1.5)
            Text("wizard.generating_payments")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Success

    private func successCard(count: Int) -> some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.Colors.success)

            Text("wizard.payments_generated \(count)")
                .font(AppTypography.title3)
                .multilineTextAlignment(.center)

            PrimaryButton(
                title: "wizard.done",
                isLoading: false
            ) {
                wizardViewModel.complete()
            }
        }
        .cardStyle()
    }

    // MARK: - Error

    private func errorCard(message: String) -> some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.Colors.error)

            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button("wizard.retry") {
                wizardViewModel.generatePayments()
            }
            .font(AppTypography.body)
            .foregroundStyle(AppTheme.Colors.primary)
        }
        .cardStyle()
    }
}
