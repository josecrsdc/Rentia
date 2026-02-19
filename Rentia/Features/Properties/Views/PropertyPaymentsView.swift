import FirebaseAuth
import SwiftUI

struct PropertyPaymentsView: View {
    let propertyId: String
    @State private var payments: [Payment] = []
    @State private var isLoading = true

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if payments.isEmpty {
                emptyState
            } else {
                paymentList
            }
        }
        .navigationTitle("tabs.payments")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PaymentDestination.self) { destination in
            switch destination {
            case .detail(let id):
                PaymentDetailView(paymentId: id)
            case .form(let id):
                PaymentFormView(paymentId: id)
            }
        }
        .onAppear { loadPayments() }
    }

    private var paymentList: some View {
        ScrollView {
            VStack(spacing: AppSpacing.medium) {
                ForEach(payments) { payment in
                    NavigationLink(
                        value: PaymentDestination.detail(payment.id ?? "")
                    ) {
                        PaymentCard(payment: payment)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.medium)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "creditcard",
            title: "properties.no_payments_recorded",
            message: "properties.payments_empty.message"
        )
    }

    private func loadPayments() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            payments = (
                try? await firestoreService.readAll(
                    from: "payments",
                    whereField: "propertyId",
                    isEqualTo: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            payments.sort { $0.date > $1.date }
            isLoading = false
        }
    }
}
