import FirebaseAuth
import Foundation

enum ReportPeriod: String, CaseIterable, Sendable {
    case month
    case quarter
    case year

    var localizedName: String {
        switch self {
        case .month: String(localized: "reports.period.month")
        case .quarter: String(localized: "reports.period.quarter")
        case .year: String(localized: "reports.period.year")
        }
    }
}

@MainActor
@Observable
final class ProfitabilityViewModel {
    var payments: [Payment] = []
    var expenses: [Expense] = []
    var selectedPeriod: ReportPeriod = .month
    var isLoading = false

    private let firestoreService: any FirestoreServiceProtocol
    let propertyId: String

    init(propertyId: String, firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.propertyId = propertyId
        self.firestoreService = firestoreService
    }

    // Computed properties react to selectedPeriod automatically via @Observable
    var filteredPayments: [Payment] {
        payments.filter { $0.status == .paid && isInPeriod($0.date) }
    }

    var filteredExpenses: [Expense] {
        expenses.filter { isInPeriod($0.date) }
    }

    var totalIncome: Double {
        filteredPayments.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var result: Double {
        totalIncome - totalExpenses
    }

    var resultIsPositive: Bool {
        result >= 0
    }

    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            async let paymentsResult: [Payment] = (
                try? await firestoreService.readAll(
                    from: "payments",
                    whereField: "propertyId",
                    isEqualTo: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            async let expensesResult: [Expense] = (
                try? await firestoreService.readAll(
                    from: "expenses",
                    whereField: "propertyId",
                    isEqualTo: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            payments = await paymentsResult
            expenses = await expensesResult
            isLoading = false
        }
    }

    private func isInPeriod(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .quarter:
            let nowQuarter = (calendar.component(.month, from: now) - 1) / 3
            let dateQuarter = (calendar.component(.month, from: date) - 1) / 3
            let nowYear = calendar.component(.year, from: now)
            let dateYear = calendar.component(.year, from: date)
            return nowQuarter == dateQuarter && nowYear == dateYear
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}
