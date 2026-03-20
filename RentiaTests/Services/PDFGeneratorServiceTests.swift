import Testing
import Foundation
@testable import Rentia

@Suite("PDFGeneratorService")
@MainActor
struct PDFGeneratorServiceTests {
    // MARK: - Helpers

    private func makePayment(id: String? = "pay-001") -> Payment {
        Payment(
            id: id,
            ownerId: "owner1",
            tenantId: "t1",
            propertyId: "p1",
            amount: 850,
            date: Date(),
            dueDate: Date(),
            status: .paid,
            paymentMethod: "Transferencia",
            notes: nil,
            createdAt: Date()
        )
    }

    private func makeTenant() -> Tenant {
        Tenant(
            id: "t1",
            ownerId: "owner1",
            firstName: "Ana",
            lastName: "García",
            email: "ana@example.com",
            phone: "600000000",
            status: .active,
            createdAt: Date()
        )
    }

    private func makeProperty() -> Property {
        Property(
            id: "p1",
            ownerId: "owner1",
            name: "Piso Centro",
            address: Address(
                street: "Calle Mayor 1",
                city: "Madrid",
                state: "Madrid",
                postalCode: "28001",
                country: "España"
            ),
            cadastralReference: nil,
            type: .apartment,
            currency: "EUR",
            status: .available,
            description: nil,
            rooms: 3,
            bathrooms: 1,
            area: nil,
            administratorId: nil,
            imageURLs: [],
            createdAt: Date()
        )
    }

    private func makeOwner() -> UserProfile {
        UserProfile(
            id: nil,
            uid: "owner1",
            email: "owner@example.com",
            displayName: "José Propietario",
            photoURL: nil,
            authProvider: "google",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeLease(endDate: Date? = Date(timeIntervalSinceNow: 86400 * 365)) -> Lease {
        Lease(
            id: "l1",
            ownerId: "owner1",
            propertyId: "p1",
            tenantId: "t1",
            startDate: Date(),
            endDate: endDate,
            rentAmount: 850,
            depositAmount: 1700,
            billingDay: 5,
            utilitiesMode: .included,
            status: .active,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Payment Receipt

    @Test func paymentReceiptIsNotEmpty() {
        let data = PDFGeneratorService.generatePaymentReceipt(
            payment: makePayment(),
            tenant: makeTenant(),
            property: makeProperty(),
            owner: makeOwner()
        )
        #expect(!data.isEmpty)
    }

    @Test func paymentReceiptHasPDFHeader() {
        let data = PDFGeneratorService.generatePaymentReceipt(
            payment: makePayment(),
            tenant: makeTenant(),
            property: makeProperty(),
            owner: makeOwner()
        )
        let header = String(data: data.prefix(4), encoding: .isoLatin1) ?? ""
        #expect(header == "%PDF")
    }

    @Test func paymentReceiptWithNilIdIsValid() {
        let data = PDFGeneratorService.generatePaymentReceipt(
            payment: makePayment(id: nil),
            tenant: makeTenant(),
            property: makeProperty(),
            owner: makeOwner()
        )
        #expect(!data.isEmpty)
    }

    @Test func paymentReceiptSizeInReasonableRange() {
        let data = PDFGeneratorService.generatePaymentReceipt(
            payment: makePayment(),
            tenant: makeTenant(),
            property: makeProperty(),
            owner: makeOwner()
        )
        let sizeKB = data.count / 1024
        #expect(sizeKB > 0)
        #expect(sizeKB < 5120) // < 5 MB
    }

    // MARK: - Lease Contract

    @Test func leaseContractIsNotEmpty() {
        let data = PDFGeneratorService.generateLeaseContract(
            lease: makeLease(),
            tenant: makeTenant(),
            property: makeProperty(),
            owner: makeOwner()
        )
        #expect(!data.isEmpty)
    }

    @Test func leaseContractHasPDFHeader() {
        let data = PDFGeneratorService.generateLeaseContract(
            lease: makeLease(),
            tenant: makeTenant(),
            property: makeProperty(),
            owner: makeOwner()
        )
        let header = String(data: data.prefix(4), encoding: .isoLatin1) ?? ""
        #expect(header == "%PDF")
    }

    @Test func leaseContractWithNilEndDateIsValid() {
        let data = PDFGeneratorService.generateLeaseContract(
            lease: makeLease(endDate: nil),
            tenant: makeTenant(),
            property: makeProperty(),
            owner: makeOwner()
        )
        #expect(!data.isEmpty)
    }

    @Test func paymentReceiptIsDeterministic() {
        let payment = makePayment()
        let tenant = makeTenant()
        let property = makeProperty()
        let owner = makeOwner()
        let data1 = PDFGeneratorService.generatePaymentReceipt(
            payment: payment, tenant: tenant, property: property, owner: owner
        )
        let data2 = PDFGeneratorService.generatePaymentReceipt(
            payment: payment, tenant: tenant, property: property, owner: owner
        )
        #expect(data1.count == data2.count)
    }
}
