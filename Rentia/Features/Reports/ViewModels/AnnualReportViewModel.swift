import FirebaseAuth
import Foundation

@MainActor
@Observable
final class AnnualReportViewModel {
    var payments: [Payment] = []
    var properties: [Property] = []
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var isLoading = false

    private let firestoreService: any FirestoreServiceProtocol

    init(firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 4)...currentYear).reversed()
    }

    var monthlyData: [[Double]] {
        properties.map { property in
            (1...12).map { month in
                paymentsForProperty(property.id ?? "", month: month)
                    .reduce(0) { $0 + $1.amount }
            }
        }
    }

    var monthlyTotals: [Double] {
        (1...12).map { month in
            payments
                .filter { payment in
                    let components = Calendar.current.dateComponents(
                        [.year, .month], from: payment.date
                    )
                    return components.year == selectedYear
                        && components.month == month
                        && payment.status == .paid
                }
                .reduce(0) { $0 + $1.amount }
        }
    }

    var annualTotal: Double {
        monthlyTotals.reduce(0, +)
    }

    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            async let propertiesResult: [Property] = (
                try? await firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            async let paymentsResult: [Payment] = (
                try? await firestoreService.readAll(
                    from: "payments",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            properties = await propertiesResult
            payments = await paymentsResult
            isLoading = false
        }
    }

    func paymentsForProperty(_ propertyId: String, month: Int) -> [Payment] {
        payments.filter { payment in
            let components = Calendar.current.dateComponents(
                [.year, .month], from: payment.date
            )
            return payment.propertyId == propertyId
                && components.year == selectedYear
                && components.month == month
                && payment.status == .paid
        }
    }

    func totalForProperty(_ propertyId: String) -> Double {
        payments
            .filter { payment in
                let year = Calendar.current.component(.year, from: payment.date)
                return payment.propertyId == propertyId
                    && year == selectedYear
                    && payment.status == .paid
            }
            .reduce(0) { $0 + $1.amount }
    }

    func exportCSV() -> String {
        var lines = ["Propiedad"]
        let monthAbbrs = (1...12).map { month -> String in
            let date = Calendar.current.date(
                from: DateComponents(year: selectedYear, month: month, day: 1)
            ) ?? Date()
            return date.formatted(.dateTime.month(.abbreviated))
        }
        lines[0] += "," + monthAbbrs.joined(separator: ",") + ",Total"

        for (index, property) in properties.enumerated() {
            let id = property.id ?? ""
            let monthValues = monthlyData[safe: index] ?? Array(repeating: 0, count: 12)
            let total = totalForProperty(id)
            let row = [property.name]
                + monthValues.map { String(format: "%.2f", $0) }
                + [String(format: "%.2f", total)]
            lines.append(row.joined(separator: ","))
        }

        let totalRow = ["TOTAL"]
            + monthlyTotals.map { String(format: "%.2f", $0) }
            + [String(format: "%.2f", annualTotal)]
        lines.append(totalRow.joined(separator: ","))

        return lines.joined(separator: "\n")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
