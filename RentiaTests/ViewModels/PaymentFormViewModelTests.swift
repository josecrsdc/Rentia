import Foundation
import Testing
@testable import Rentia

@Suite("PaymentFormViewModel")
@MainActor
struct PaymentFormViewModelTests {

    // MARK: - Helpers

    private func makeVM() -> (PaymentFormViewModel, MockFirestoreService) {
        let firestore = MockFirestoreService()
        return (PaymentFormViewModel(firestoreService: firestore), firestore)
    }

    private func lease(
        id: String = UUID().uuidString,
        tenantId: String = "t1",
        propertyId: String = "p1",
        status: LeaseStatus = .active,
        rentAmount: Double = 800,
        billingDay: Int = 5
    ) -> Lease {
        Lease(
            id: id,
            ownerId: "o1",
            propertyId: propertyId,
            tenantId: tenantId,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            rentAmount: rentAmount,
            depositAmount: rentAmount * 2,
            billingDay: billingDay,
            utilitiesMode: .none,
            status: status,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func property(id: String) -> Property {
        Property(
            id: id,
            ownerId: "o1",
            name: "Piso \(id)",
            address: .empty,
            type: .apartment,
            currency: "EUR",
            status: .available,
            rooms: 2,
            bathrooms: 1,
            createdAt: Date()
        )
    }

    private func tenant(id: String) -> Tenant {
        Tenant(
            id: id,
            ownerId: "o1",
            firstName: "Test",
            lastName: "User",
            email: "test@test.com",
            phone: "600000000",
            status: .active,
            createdAt: Date()
        )
    }

    // MARK: - filteredProperties

    @Test func filteredPropertiesEmptyTenantIdReturnsAll() {
        let (vm, _) = makeVM()
        vm.properties = [property(id: "p1"), property(id: "p2")]
        vm.tenantId = ""
        #expect(vm.filteredProperties.count == 2)
    }

    @Test func filteredPropertiesFiltersToActiveLeasedProperties() {
        let (vm, _) = makeVM()
        vm.properties = [property(id: "p1"), property(id: "p2")]
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", status: .active)]
        vm.tenantId = "t1"
        #expect(vm.filteredProperties.count == 1)
        #expect(vm.filteredProperties.first?.id == "p1")
    }

    @Test func filteredPropertiesIgnoresDraftLeases() {
        let (vm, _) = makeVM()
        vm.properties = [property(id: "p1"), property(id: "p2")]
        vm.leases = [
            lease(tenantId: "t1", propertyId: "p1", status: .draft),
            lease(tenantId: "t1", propertyId: "p2", status: .expired),
        ]
        vm.tenantId = "t1"
        #expect(vm.filteredProperties.isEmpty)
    }

    @Test func filteredPropertiesExcludesPropertiesWithNilId() {
        let (vm, _) = makeVM()
        let nilIdProperty = Property(
            id: nil,
            ownerId: "o1",
            name: "NilId",
            address: .empty,
            type: .apartment,
            currency: "EUR",
            status: .available,
            rooms: 1,
            bathrooms: 1,
            createdAt: Date()
        )
        vm.properties = [nilIdProperty]
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", status: .active)]
        vm.tenantId = "t1"
        #expect(vm.filteredProperties.isEmpty)
    }

    @Test func filteredPropertiesNoLeasesForTenantReturnsEmpty() {
        let (vm, _) = makeVM()
        vm.properties = [property(id: "p1"), property(id: "p2")]
        vm.leases = [lease(tenantId: "t2", propertyId: "p1", status: .active)]
        vm.tenantId = "t1"
        #expect(vm.filteredProperties.isEmpty)
    }

    // MARK: - filteredTenants

    @Test func filteredTenantsEmptyPropertyIdReturnsAll() {
        let (vm, _) = makeVM()
        vm.tenants = [tenant(id: "t1"), tenant(id: "t2")]
        vm.propertyId = ""
        #expect(vm.filteredTenants.count == 2)
    }

    @Test func filteredTenantsFiltersToActiveLeasedTenants() {
        let (vm, _) = makeVM()
        vm.tenants = [tenant(id: "t1"), tenant(id: "t2")]
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", status: .active)]
        vm.propertyId = "p1"
        #expect(vm.filteredTenants.count == 1)
        #expect(vm.filteredTenants.first?.id == "t1")
    }

    @Test func filteredTenantsIgnoresNonActiveLeases() {
        let (vm, _) = makeVM()
        vm.tenants = [tenant(id: "t1")]
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", status: .expired)]
        vm.propertyId = "p1"
        #expect(vm.filteredTenants.isEmpty)
    }

    @Test func filteredTenantsExcludesTenantsWithNilId() {
        let (vm, _) = makeVM()
        let nilTenant = Tenant(
            id: nil,
            ownerId: "o1",
            firstName: "Nil",
            lastName: "User",
            email: "nil@test.com",
            phone: "600000001",
            status: .active,
            createdAt: Date()
        )
        vm.tenants = [nilTenant]
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", status: .active)]
        vm.propertyId = "p1"
        #expect(vm.filteredTenants.isEmpty)
    }

    // MARK: - autoFillFromLease

    @Test func autoFillSetsActiveLease() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", rentAmount: 800)]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        #expect(vm.activeLease != nil)
    }

    @Test func autoFillFillsAmountWhenEmpty() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", rentAmount: 800)]
        vm.amount = ""
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        #expect(vm.amount == "800.00")
    }

    @Test func autoFillDoesNotOverwriteExistingNonZeroAmount() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", rentAmount: 800)]
        vm.amount = "500.00"
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        #expect(vm.amount == "500.00")
    }

    @Test func autoFillClearsActiveLeaseWhenBothIdsEmpty() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1")]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        #expect(vm.activeLease != nil)
        vm.tenantId = ""
        vm.propertyId = ""
        #expect(vm.activeLease == nil)
    }

    @Test func autoFillSetsNilWhenNoMatchingLease() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t2", propertyId: "p2")]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        #expect(vm.activeLease == nil)
    }

    @Test func autoFillIgnoresNonActiveLeases() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", status: .expired)]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        #expect(vm.activeLease == nil)
    }

    @Test func autoFillCapsBillingDayAt28() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", billingDay: 31)]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        let day = Calendar.current.component(.day, from: vm.dueDate)
        #expect(day <= 28)
    }

    @Test func autoFillSetsDueDateToValidCalendarDate() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", billingDay: 15)]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        let day = Calendar.current.component(.day, from: vm.dueDate)
        #expect(day == 15)
    }

    // MARK: - isFormValid

    @Test func isFormValidFalseWhenTenantIdEmpty() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", rentAmount: 800)]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        vm.tenantId = ""
        #expect(vm.isFormValid == false)
    }

    @Test func isFormValidFalseWhenPropertyIdEmpty() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", rentAmount: 800)]
        vm.tenantId = "t1"
        vm.propertyId = ""
        #expect(vm.isFormValid == false)
    }

    @Test func isFormValidFalseWhenAmountZero() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", rentAmount: 800)]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        vm.amount = "0"
        #expect(vm.isFormValid == false)
    }

    @Test func isFormValidFalseWhenAmountNotANumber() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", rentAmount: 800)]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        vm.amount = "abc"
        #expect(vm.isFormValid == false)
    }

    @Test func isFormValidFalseWhenNoActiveLease() {
        let (vm, _) = makeVM()
        vm.tenantId = "t1"
        vm.propertyId = "p1"
        vm.amount = "800.00"
        vm.activeLease = nil
        #expect(vm.isFormValid == false)
    }

    @Test func isFormValidTrueWhenAllConditionsMet() {
        let (vm, _) = makeVM()
        vm.leases = [lease(tenantId: "t1", propertyId: "p1", rentAmount: 800)]
        vm.propertyId = "p1"
        vm.tenantId = "t1"
        #expect(vm.isFormValid == true)
    }
}
