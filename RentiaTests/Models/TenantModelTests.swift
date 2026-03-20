import Testing
import Foundation
@testable import Rentia

@Suite("Tenant Model")
struct TenantModelTests {
    private func makeTenant(firstName: String = "Ana", lastName: String = "García") -> Tenant {
        Tenant(
            id: "t1",
            ownerId: "owner1",
            firstName: firstName,
            lastName: lastName,
            email: "ana@example.com",
            phone: "600000000",
            status: .active,
            createdAt: Date()
        )
    }

    @Test func fullNameConcatenatesFirstAndLast() {
        let tenant = makeTenant(firstName: "Juan", lastName: "Pérez")
        #expect(tenant.fullName == "Juan Pérez")
    }

    @Test func fullNameWithMultiWordLastName() {
        let tenant = makeTenant(firstName: "María", lastName: "López García")
        #expect(tenant.fullName == "María López García")
    }

    @Test func tenantStatusActiveRawValue() {
        #expect(TenantStatus.active.rawValue == "active")
    }

    @Test func tenantStatusInactiveRawValue() {
        #expect(TenantStatus.inactive.rawValue == "inactive")
    }

    @Test func tenantStatusAllCasesCount() {
        #expect(TenantStatus.allCases.count == 2)
    }
}
