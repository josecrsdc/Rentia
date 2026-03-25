import FirebaseAuth
import SwiftUI

struct ExtendLeaseView: View {
    let lease: Lease
    let onExtended: () -> Void
    @State private var newEndDate: Date
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let firestoreService = FirestoreService()
    private let paymentGenerationService = PaymentGenerationService()

    init(lease: Lease, onExtended: @escaping () -> Void) {
        self.lease = lease
        self.onExtended = onExtended
        let currentEnd = lease.endDate ?? Date()
        let defaultEnd = Calendar.current.date(byAdding: .year, value: 1, to: currentEnd) ?? currentEnd
        _newEndDate = State(initialValue: defaultEnd)
    }

    private var minimumDate: Date {
        let currentEnd = lease.endDate ?? Date()
        return Calendar.current.date(byAdding: .day, value: 1, to: currentEnd) ?? currentEnd
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                Form {
                    currentDatesSection
                    newEndDateSection
                    infoSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("leases.extend.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button(String(localized: "leases.extend.button")) {
                            Task { await extendLease() }
                        }
                    }
                }
            }
            .alert("common.error", isPresented: $showError) {
                Button("common.accept", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var currentDatesSection: some View {
        Section("leases.extend.current_dates") {
            LabeledContent(
                String(localized: "leases.start_date"),
                value: lease.startDate.formatted(date: .abbreviated, time: .omitted)
            )
            if let endDate = lease.endDate {
                LabeledContent(
                    String(localized: "leases.end_date"),
                    value: endDate.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
    }

    private var newEndDateSection: some View {
        Section {
            DatePicker(
                String(localized: "leases.extend.new_end_date"),
                selection: $newEndDate,
                in: minimumDate...,
                displayedComponents: .date
            )
            .accessibilityLabel(String(localized: "leases.extend.new_end_date"))
        } header: {
            Text("leases.extend.new_end_date")
        }
    }

    private var infoSection: some View {
        Section {
            Label("leases.extend.payments_hint", systemImage: "info.circle")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    private func extendLease() async {
        guard let leaseId = lease.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        var updatedLease = lease
        updatedLease.endDate = newEndDate
        updatedLease.updatedAt = Date()

        do {
            try await firestoreService.update(updatedLease, id: leaseId, in: "leases")
            _ = try? await paymentGenerationService.generatePayments(
                for: updatedLease,
                leaseId: leaseId,
                ownerId: userId
            )
            isLoading = false
            onExtended()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}
