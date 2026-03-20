import Foundation
import Testing
@testable import Rentia

// MARK: - PaymentStatus

@Suite("PaymentStatus")
struct PaymentStatusTests {
    @Test func rawValues() {
        #expect(PaymentStatus.pending.rawValue == "pending")
        #expect(PaymentStatus.paid.rawValue == "paid")
        #expect(PaymentStatus.overdue.rawValue == "overdue")
        #expect(PaymentStatus.partial.rawValue == "partial")
    }

    @Test func icons() {
        #expect(PaymentStatus.pending.icon == "clock")
        #expect(PaymentStatus.paid.icon == "checkmark.circle.fill")
        #expect(PaymentStatus.overdue.icon == "exclamationmark.triangle.fill")
        #expect(PaymentStatus.partial.icon == "chart.pie")
    }
}

// MARK: - ExpenseCategory

@Suite("ExpenseCategory")
struct ExpenseCategoryTests {
    @Test func codableRoundTrip() throws {
        for category in ExpenseCategory.allCases {
            let encoded = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(ExpenseCategory.self, from: encoded)
            #expect(decoded == category)
        }
    }

    @Test func icons() {
        #expect(ExpenseCategory.ibi.icon == "building.columns")
        #expect(ExpenseCategory.community.icon == "person.3")
        #expect(ExpenseCategory.insurance.icon == "shield")
        #expect(ExpenseCategory.repair.icon == "wrench.and.screwdriver")
        #expect(ExpenseCategory.utilities.icon == "bolt")
        #expect(ExpenseCategory.mortgage.icon == "house.and.flag")
        #expect(ExpenseCategory.management.icon == "briefcase")
        #expect(ExpenseCategory.other.icon == "ellipsis.circle")
    }
}

// MARK: - LeaseStatus

@Suite("LeaseStatus")
struct LeaseStatusTests {
    @Test func rawValues() {
        #expect(LeaseStatus.draft.rawValue == "draft")
        #expect(LeaseStatus.active.rawValue == "active")
        #expect(LeaseStatus.expired.rawValue == "expired")
        #expect(LeaseStatus.ended.rawValue == "ended")
    }
}

// MARK: - PropertyType

@Suite("PropertyType.supportsRoomsBathrooms")
struct PropertyTypeTests {
    @Test func apartmentSupports() {
        #expect(PropertyType.apartment.supportsRoomsBathrooms == true)
    }

    @Test func houseSupports() {
        #expect(PropertyType.house.supportsRoomsBathrooms == true)
    }

    @Test func commercialSupports() {
        #expect(PropertyType.commercial.supportsRoomsBathrooms == true)
    }

    @Test func garageDoesNotSupport() {
        #expect(PropertyType.garage.supportsRoomsBathrooms == false)
    }

    @Test func landDoesNotSupport() {
        #expect(PropertyType.land.supportsRoomsBathrooms == false)
    }
}

// MARK: - PropertyStatus custom decoder

@Suite("PropertyStatus custom decoder")
struct PropertyStatusTests {
    @Test func knownValueDecodes() throws {
        let json = #""available""#.data(using: .utf8)!
        let status = try JSONDecoder().decode(PropertyStatus.self, from: json)
        #expect(status == .available)
    }

    @Test func unknownValueFallsBackToAvailable() throws {
        let json = #""occupied""#.data(using: .utf8)!
        let status = try JSONDecoder().decode(PropertyStatus.self, from: json)
        #expect(status == .available)
    }

    @Test func maintenanceDecodes() throws {
        let json = #""maintenance""#.data(using: .utf8)!
        let status = try JSONDecoder().decode(PropertyStatus.self, from: json)
        #expect(status == .maintenance)
    }
}

// MARK: - Date.isOverdue

@Suite("Date.isOverdue")
struct DateIsOverdueTests {
    @Test func pastDateIsOverdue() {
        let past = Date(timeIntervalSinceNow: -86400)
        #expect(past.isOverdue == true)
    }

    @Test func futureDateIsNotOverdue() {
        let future = Date(timeIntervalSinceNow: 86400)
        #expect(future.isOverdue == false)
    }
}

// MARK: - String extensions

@Suite("String extensions")
struct StringExtensionTests {
    @Test func validEmail() {
        #expect("user@example.com".isValidEmail == true)
    }

    @Test func invalidEmailMissingAt() {
        #expect("userexample.com".isValidEmail == false)
    }

    @Test func invalidEmailEmpty() {
        #expect("".isValidEmail == false)
    }

    @Test func validPhone() {
        #expect("+34600000000".isValidPhone == true)
    }

    @Test func validPhoneWithSpaces() {
        #expect("600 000 000".isValidPhone == true)
    }

    @Test func invalidPhoneTooShort() {
        #expect("123".isValidPhone == false)
    }

    @Test func trimmedRemovesWhitespace() {
        #expect("  hello  ".trimmed == "hello")
    }

    @Test func trimmedEmptyStaysEmpty() {
        #expect("  ".trimmed == "")
    }

    @Test func isNotEmptyTrue() {
        #expect("hello".isNotEmpty == true)
    }

    @Test func isNotEmptyFalseForWhitespace() {
        #expect("  ".isNotEmpty == false)
    }

    @Test func isNotEmptyFalseForEmpty() {
        #expect("".isNotEmpty == false)
    }
}
