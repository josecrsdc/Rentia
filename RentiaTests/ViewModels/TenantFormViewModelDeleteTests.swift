import Foundation
import Testing
@testable import Rentia

@Suite("TenantFormViewModel — delete")
@MainActor
struct TenantFormViewModelDeleteTests {

    // MARK: - Helpers

    private func makeVM(leases: [Lease] = []) -> (TenantFormViewModel, MockFirestoreService) {
        let firestore = MockFirestoreService()
        firestore.leasesResult = leases
        return (TenantFormViewModel(firestoreService: firestore), firestore)
    }

    private func activeLease(tenantId: String = "t1") -> Lease {
        Lease(
            id: UUID().uuidString,
            ownerId: "o1",
            propertyId: "p1",
            tenantId: tenantId,
            startDate: Date(),
            endDate: nil,
            rentAmount: 800,
            depositAmount: 1600,
            billingDay: 5,
            utilitiesMode: .none,
            status: .active,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func endedLease(tenantId: String = "t1") -> Lease {
        Lease(
            id: UUID().uuidString,
            ownerId: "o1",
            propertyId: "p1",
            tenantId: tenantId,
            startDate: Date(),
            endDate: Date(timeIntervalSinceNow: -86_400),
            rentAmount: 800,
            depositAmount: 1600,
            billingDay: 5,
            utilitiesMode: .none,
            status: .ended,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Tests

    @Test func deleteBlockedWhenActiveLeaseExists() async {
        let (vm, firestore) = makeVM(leases: [activeLease()])

        vm.delete(tenantId: "t1")
        await Task.yield()

        #expect(vm.showError == true)
        #expect(vm.errorMessage != nil)
        #expect(firestore.deleteCallCount == 0)
        #expect(vm.didSave == false)
    }

    @Test func deleteSucceedsWhenNoActiveLeases() async {
        let (vm, firestore) = makeVM(leases: [endedLease()])

        vm.delete(tenantId: "t1")
        await Task.yield()

        #expect(vm.didSave == true)
        #expect(firestore.deleteCallCount == 1)
        #expect(firestore.lastDeletedId == "t1")
    }

    @Test func deleteSucceedsWhenNoLeasesAtAll() async {
        let (vm, firestore) = makeVM(leases: [])

        vm.delete(tenantId: "t1")
        await Task.yield()

        #expect(vm.didSave == true)
        #expect(firestore.deleteCallCount == 1)
    }

    @Test func deleteBlockedWhenMixedLeasesContainsOneActive() async {
        let (vm, firestore) = makeVM(leases: [endedLease(), activeLease()])

        vm.delete(tenantId: "t1")
        await Task.yield()

        #expect(vm.showError == true)
        #expect(firestore.deleteCallCount == 0)
    }

    @Test func deleteShowsErrorWhenFirestoreReadFails() async {
        let (vm, firestore) = makeVM()
        firestore.shouldThrow = true

        vm.delete(tenantId: "t1")
        await Task.yield()

        #expect(vm.showError == true)
        #expect(vm.errorMessage != nil)
        #expect(firestore.deleteCallCount == 0)
        #expect(vm.isLoading == false)
    }
}
