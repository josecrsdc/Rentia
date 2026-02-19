import SwiftUI

struct PaymentDetailView: View {
    let paymentId: String
    @State private var payment: Payment?
    @State private var isLoading = true

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let payment {
                paymentContent(payment)
            }
        }
        .navigationTitle(String(localized: "Detalle del Pago"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(
                    value: PaymentDestination.form(paymentId)
                ) {
                    Text(String(localized: "Editar"))
                }
            }
        }
        .onAppear { loadPayment() }
    }

    private func paymentContent(_ payment: Payment) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                amountHeader(payment)
                detailsCard(payment)
            }
            .padding(AppSpacing.medium)
        }
    }

    private func amountHeader(_ payment: Payment) -> some View {
        VStack(spacing: AppSpacing.medium) {
            Text(payment.amount.formatted(.currency(code: "USD")))
                .font(AppTypography.moneyLarge)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(payment.status.displayName)
                .font(AppTypography.headline)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(statusColor(for: payment.status).opacity(0.15))
                .foregroundStyle(statusColor(for: payment.status))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.extraLarge)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
        )
        .shadow(
            color: AppTheme.Shadows.card,
            radius: AppTheme.Shadows.cardRadius,
            x: AppTheme.Shadows.cardX,
            y: AppTheme.Shadows.cardY
        )
    }

    private func detailsCard(_ payment: Payment) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Informacion"))
                .font(AppTypography.title3)

            detailRow(
                icon: "calendar",
                label: String(localized: "Fecha de pago"),
                value: payment.date.shortFormatted
            )

            detailRow(
                icon: "calendar.badge.clock",
                label: String(localized: "Fecha de vencimiento"),
                value: payment.dueDate.shortFormatted
            )

            if let method = payment.paymentMethod, !method.isEmpty {
                detailRow(
                    icon: "creditcard",
                    label: String(localized: "Metodo de pago"),
                    value: method
                )
            }

            if let notes = payment.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(
                        String(localized: "Notas"),
                        systemImage: "note.text"
                    )
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                    Text(notes)
                        .font(AppTypography.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func detailRow(
        icon: String,
        label: String,
        value: String
    ) -> some View {
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
        }
    }

    private func statusColor(for status: PaymentStatus) -> Color {
        switch status {
        case .paid: AppTheme.Colors.success
        case .pending: AppTheme.Colors.warning
        case .overdue: AppTheme.Colors.error
        case .partial: AppTheme.Colors.accent
        }
    }

    private func loadPayment() {
        Task {
            do {
                payment = try await firestoreService.read(
                    id: paymentId,
                    from: "payments"
                )
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}
