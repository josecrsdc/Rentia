import SwiftUI

struct PaymentDetailView: View {
    let paymentId: String
    @State private var payment: Payment?
    @State private var tenant: Tenant?
    @State private var property: Property?
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

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
        .alert(
            String(localized: "Eliminar Pago"),
            isPresented: $showDeleteConfirmation
        ) {
            Button(String(localized: "Cancelar"), role: .cancel) {}
            Button(String(localized: "Eliminar"), role: .destructive) {
                deletePayment()
            }
        } message: {
            Text(
                String(localized: "Esta accion no se puede deshacer. Se eliminara el pago permanentemente.")
            )
        }
    }

    private func paymentContent(_ payment: Payment) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                amountHeader(payment)
                assignmentCard
                detailsCard(payment)
                deleteButton
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

    // MARK: - Assignment Card

    private var assignmentCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Asignacion"))
                .font(AppTypography.title3)

            if let tenant {
                HStack(spacing: AppSpacing.small) {
                    Text(tenantInitials(tenant))
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.Colors.primary)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tenant.fullName)
                            .font(AppTypography.body)

                        Text(tenant.email)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(tenant.status.displayName)
                        .font(AppTypography.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.extraSmall)
                        .background(
                            tenant.status == .active
                                ? AppTheme.Colors.success.opacity(0.15)
                                : AppTheme.Colors.textSecondary.opacity(0.15)
                        )
                        .foregroundStyle(
                            tenant.status == .active
                                ? AppTheme.Colors.success
                                : AppTheme.Colors.textSecondary
                        )
                        .clipShape(Capsule())
                }
            } else {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "person.slash")
                        .foregroundStyle(AppTheme.Colors.textLight)
                    Text(String(localized: "Inquilino no encontrado"))
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Divider()

            if let property {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: property.type.icon)
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppTheme.CornerRadius.small
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(property.name)
                            .font(AppTypography.body)

                        Text(property.address)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(property.status.displayName)
                        .font(AppTypography.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.extraSmall)
                        .background(AppTheme.Colors.primary.opacity(0.1))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .clipShape(Capsule())
                }
            } else {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "building.2.slash")
                        .foregroundStyle(AppTheme.Colors.textLight)
                    Text(String(localized: "Propiedad no encontrada"))
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
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

    private func tenantInitials(_ tenant: Tenant) -> String {
        let first = tenant.firstName.prefix(1).uppercased()
        let last = tenant.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text(String(localized: "Eliminar Pago"))
            }
            .font(AppTypography.body)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.medium)
            .background(AppTheme.Colors.error.opacity(0.1))
            .foregroundStyle(AppTheme.Colors.error)
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
            )
        }
    }

    private func deletePayment() {
        Task {
            do {
                try await firestoreService.delete(
                    id: paymentId,
                    from: "payments"
                )
                dismiss()
            } catch {
                // Handle error
            }
        }
    }

    private func loadPayment() {
        Task {
            do {
                let loadedPayment: Payment = try await firestoreService.read(
                    id: paymentId,
                    from: "payments"
                )
                payment = loadedPayment
                async let tenantResult: Tenant = firestoreService.read(
                    id: loadedPayment.tenantId,
                    from: "tenants"
                )
                async let propertyResult: Property = firestoreService.read(
                    id: loadedPayment.propertyId,
                    from: "properties"
                )
                tenant = try? await tenantResult
                property = try? await propertyResult
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}
