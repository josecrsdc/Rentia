import Foundation
import Testing
@testable import Rentia

@Suite("AnnualReportViewModel")
@MainActor
struct AnnualReportViewModelTests {
    private let currentYear = Calendar.current.component(.year, from: Date())

    private func makeVM() -> AnnualReportViewModel {
        AnnualReportViewModel(firestoreService: MockFirestoreService())
    }

    private func payment(
        propertyId: String = "p1",
        amount: Double,
        month: Int,
        year: Int? = nil,
        status: PaymentStatus = .paid
    ) -> Payment {
        let targetYear = year ?? Calendar.current.component(.year, from: Date())
        let date = Calendar.current.date(from: DateComponents(year: targetYear, month: month, day: 15))!
        return Payment(
            id: UUID().uuidString,
            ownerId: "o1",
            tenantId: "t1",
            propertyId: propertyId,
            amount: amount,
            date: date,
            dueDate: date,
            status: status,
            paymentMethod: nil,
            notes: nil,
            createdAt: Date()
        )
    }

    private func property(id: String = "p1", name: String = "Piso Test") -> Property {
        Property(
            id: id,
            ownerId: "o1",
            name: name,
            address: .empty,
            cadastralReference: nil,
            type: .apartment,
            currency: "EUR",
            status: .available,
            description: nil,
            rooms: 2,
            bathrooms: 1,
            area: nil,
            administratorId: nil,
            imageURLs: [],
            createdAt: Date()
        )
    }

    // MARK: - monthlyTotals

    @Test func monthlyTotalsHasTwelveElements() {
        let vm = makeVM()
        #expect(vm.monthlyTotals.count == 12)
    }

    @Test func monthlyDataMatchesPropertiesCountAndMonths() {
        let vm = makeVM()
        vm.selectedYear = currentYear
        vm.properties = [property(id: "p1"), property(id: "p2")]
        vm.payments = [
            payment(propertyId: "p1", amount: 800, month: 1),
            payment(propertyId: "p2", amount: 600, month: 2),
        ]
        #expect(vm.monthlyData.count == 2)
        #expect(vm.monthlyData.allSatisfy { $0.count == 12 })
        #expect(vm.monthlyData[0][0] == 800)
        #expect(vm.monthlyData[1][1] == 600)
    }

    @Test func monthlyTotalsSumsCorrectlyByMonth() {
        let vm = makeVM()
        vm.selectedYear = currentYear
        vm.payments = [
            payment(amount: 800, month: 1),
            payment(amount: 500, month: 1),
            payment(amount: 300, month: 3),
        ]
        #expect(vm.monthlyTotals[0] == 1300) // January (index 0)
        #expect(vm.monthlyTotals[2] == 300)  // March (index 2)
        #expect(vm.monthlyTotals[1] == 0)    // February (index 1)
    }

    @Test func monthlyTotalsExcludesWrongYear() {
        let vm = makeVM()
        vm.selectedYear = currentYear
        vm.payments = [
            payment(amount: 800, month: 1, year: currentYear - 1),
        ]
        #expect(vm.monthlyTotals.allSatisfy { $0 == 0 })
    }

    @Test func monthlyTotalsExcludesNonPaid() {
        let vm = makeVM()
        vm.selectedYear = currentYear
        vm.payments = [
            payment(amount: 800, month: 1, status: .pending),
            payment(amount: 500, month: 1, status: .overdue),
        ]
        #expect(vm.monthlyTotals[0] == 0)
    }

    // MARK: - annualTotal

    @Test func annualTotalEqualsSumOfMonthlyTotals() {
        let vm = makeVM()
        vm.selectedYear = currentYear
        vm.payments = [
            payment(amount: 800, month: 1),
            payment(amount: 500, month: 6),
            payment(amount: 300, month: 12),
        ]
        #expect(vm.annualTotal == vm.monthlyTotals.reduce(0, +))
        #expect(vm.annualTotal == 1600)
    }

    // MARK: - availableYears

    @Test func availableYearsHasFiveElements() {
        let vm = makeVM()
        #expect(vm.availableYears.count == 5)
    }

    @Test func availableYearsFirstIsCurrentYear() {
        let vm = makeVM()
        #expect(vm.availableYears.first == currentYear)
    }

    // MARK: - exportCSV

    @Test func exportCSVHeaderStartsWithPropiedad() {
        let vm = makeVM()
        let csv = vm.exportCSV()
        let firstLine = csv.split(separator: "\n", omittingEmptySubsequences: false).first.map(String.init) ?? ""
        #expect(firstLine.hasPrefix("Propiedad"))
    }

    @Test func exportCSVHeaderHasFourteenColumns() {
        let vm = makeVM()
        let csv = vm.exportCSV()
        let firstLine = csv.split(separator: "\n").first.map(String.init) ?? ""
        let columns = firstLine.split(separator: ",")
        // Propiedad + 12 months + Total = 14
        #expect(columns.count == 14)
    }

    @Test func exportCSVLastRowStartsWithTOTAL() {
        let vm = makeVM()
        vm.properties = [property()]
        vm.payments = [payment(amount: 800, month: 1)]
        let csv = vm.exportCSV()
        let lines = csv.split(separator: "\n").map(String.init)
        #expect(lines.last?.hasPrefix("TOTAL") == true)
    }

    @Test func exportCSVWithNoPropertiesHasTwoLines() {
        let vm = makeVM()
        vm.properties = []
        vm.payments = []
        let csv = vm.exportCSV()
        let lines = csv.split(separator: "\n").map(String.init)
        // header + TOTAL row
        #expect(lines.count == 2)
    }

    @Test func totalForPropertyOnlyCountsMatchingPropertyAndYear() {
        let vm = makeVM()
        vm.selectedYear = currentYear
        vm.payments = [
            payment(propertyId: "p1", amount: 800, month: 1),
            payment(propertyId: "p1", amount: 500, month: 2),
            payment(propertyId: "p2", amount: 300, month: 1),
            payment(propertyId: "p1", amount: 200, month: 1, year: currentYear - 1),
        ]
        #expect(vm.totalForProperty("p1") == 1300)
    }
}
