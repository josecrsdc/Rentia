import FirebaseAuth
import Foundation

enum WizardStep: Int, CaseIterable {
    case property
    case tenant
    case lease
    case generatePayments

    var labelKey: String {
        switch self {
        case .property: String(localized: "wizard.step.property")
        case .tenant: String(localized: "wizard.step.tenant")
        case .lease: String(localized: "wizard.step.lease")
        case .generatePayments: String(localized: "wizard.step.payments")
        }
    }
}

@Observable
final class PropertyWizardViewModel {
    var currentStep: WizardStep = .property
    var isCompleted = false

    // Accumulated context
    var createdPropertyId: String?
    var createdPropertyName: String?
    var createdPropertyCurrency: String?
    var createdTenantId: String?
    var createdTenantName: String?
    var createdLeaseId: String?
    var createdLease: Lease?

    // Payment generation
    var isGeneratingPayments = false
    var generatedPaymentCount: Int?
    var paymentError: String?

    private let firestoreService = FirestoreService()
    private let paymentGenerationService = PaymentGenerationService()

    var stepIndex: Int {
        currentStep.rawValue
    }

    var totalSteps: Int {
        WizardStep.allCases.count
    }

    var stepLabels: [String] {
        WizardStep.allCases.map(\.labelKey)
    }

    func advanceFromProperty(savedId: String) {
        createdPropertyId = savedId

        Task {
            do {
                let property: Property = try await firestoreService.read(
                    id: savedId,
                    from: "properties"
                )
                createdPropertyName = property.name
                createdPropertyCurrency = property.currency
            } catch {
                createdPropertyName = savedId
            }
            currentStep = .tenant
        }
    }

    func advanceFromTenant(savedId: String) {
        createdTenantId = savedId

        Task {
            do {
                let tenant: Tenant = try await firestoreService.read(
                    id: savedId,
                    from: "tenants"
                )
                createdTenantName = tenant.fullName
            } catch {
                createdTenantName = savedId
            }
            currentStep = .lease
        }
    }

    func advanceFromLease(savedId: String) {
        createdLeaseId = savedId

        Task {
            do {
                let lease: Lease = try await firestoreService.read(
                    id: savedId,
                    from: "leases"
                )
                createdLease = lease
            } catch {
                // Lease was saved, continue even if re-read fails
            }
            currentStep = .generatePayments
        }
    }

    func generatePayments() {
        guard let lease = createdLease,
              let userId = Auth.auth().currentUser?.uid else { return }

        isGeneratingPayments = true
        paymentError = nil

        Task {
            do {
                let count = try await paymentGenerationService.generatePayments(
                    for: lease,
                    ownerId: userId
                )
                generatedPaymentCount = count
            } catch {
                paymentError = error.localizedDescription
            }
            isGeneratingPayments = false
        }
    }

    func complete() {
        isCompleted = true
    }
}
