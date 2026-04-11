import FirebaseAuth
import Foundation

@Observable
final class PaymentFormViewModel {
    var tenantId = "" {
        didSet { autoFillFromLease() }
    }
    var propertyId = "" {
        didSet { autoFillFromLease() }
    }
    var amount = ""
    var date = Date()
    var dueDate = Date()
    var status: PaymentStatus = .pending
    var paymentMethod = ""
    var notes = ""
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var didSave = false

    var tenants: [Tenant] = []
    var properties: [Property] = []
    var leases: [Lease] = []
    var activeLease: Lease?

    private let firestoreService: any FirestoreServiceProtocol
    private var editingPaymentId: String?

    init(firestoreService: any FirestoreServiceProtocol = FirestoreService()) {
        self.firestoreService = firestoreService
    }

    var isEditing: Bool {
        editingPaymentId != nil
    }

    var isFormValid: Bool {
        tenantId.isNotEmpty
        && propertyId.isNotEmpty
        && (Double(amount) ?? 0) > 0
        && (activeLease != nil || editingPaymentId != nil)
    }

    var filteredProperties: [Property] {
        guard tenantId.isNotEmpty else { return properties }
        let leasedPropertyIds = Set(
            leases
                .filter { $0.status == .active && $0.tenantId == tenantId }
                .map(\.propertyId)
        )
        return properties.filter { property in
            guard let id = property.id else { return false }
            return leasedPropertyIds.contains(id)
        }
    }

    var filteredTenants: [Tenant] {
        guard propertyId.isNotEmpty else { return tenants }
        let leasedTenantIds = Set(
            leases
                .filter { $0.status == .active && $0.propertyId == propertyId }
                .map(\.tenantId)
        )
        return tenants.filter { tenant in
            guard let id = tenant.id else { return false }
            return leasedTenantIds.contains(id)
        }
    }

    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                async let tenantsResult: [Tenant] = firestoreService.readAll(
                    from: "tenants",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let propertiesResult: [Property] = firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let leasesResult: [Lease] = firestoreService.readAll(
                    from: "leases",
                    whereField: "ownerId",
                    isEqualTo: userId
                )

                tenants = try await tenantsResult
                properties = try await propertiesResult
                leases = try await leasesResult
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    func loadPayment(id: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        editingPaymentId = id
        isLoading = true

        Task {
            do {
                // Cargamos el pago y los datos de contexto concurrentemente.
                // Es necesario esperar a que `leases` esté poblado antes de asignar
                // `tenantId`/`propertyId`, ya que sus `didSet` disparan `autoFillFromLease()`.
                async let paymentResult: Payment = firestoreService.read(
                    id: id,
                    from: "payments"
                )
                async let tenantsResult: [Tenant] = firestoreService.readAll(
                    from: "tenants",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let propertiesResult: [Property] = firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
                async let leasesResult: [Lease] = firestoreService.readAll(
                    from: "leases",
                    whereField: "ownerId",
                    isEqualTo: userId
                )

                let payment = try await paymentResult
                tenants = try await tenantsResult
                properties = try await propertiesResult
                leases = try await leasesResult

                // Asignamos los campos que no tienen efectos secundarios primero.
                // `amount` se asigna antes de `tenantId`/`propertyId` para que
                // `autoFillFromLease()` no lo sobreescriba (solo rellena si está vacío).
                amount = String(format: "%.2f", payment.amount)
                status = payment.status
                paymentMethod = payment.paymentMethod ?? ""
                notes = payment.notes ?? ""

                // Asignar tenantId y propertyId ahora que `leases` ya está cargado.
                // Los `didSet` disparan `autoFillFromLease()` y encontrarán el contrato correcto.
                tenantId = payment.tenantId
                propertyId = payment.propertyId

                // Restauramos las fechas originales del pago, sobreescribiendo cualquier
                // cálculo de fecha que haya hecho `autoFillFromLease()`.
                date = payment.date
                dueDate = payment.dueDate
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func save() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        if activeLease == nil && editingPaymentId == nil {
            errorMessage = String(localized: "payments.error.no_active_lease")
            showError = true
            return
        }

        isLoading = true

        let payment = Payment(
            id: editingPaymentId,
            ownerId: userId,
            tenantId: tenantId,
            propertyId: propertyId,
            leaseId: activeLease?.id,
            amount: Double(amount) ?? 0,
            date: date,
            dueDate: dueDate,
            status: status,
            paymentMethod: paymentMethod.trimmed.isEmpty
                ? nil : paymentMethod.trimmed,
            notes: notes.trimmed.isEmpty ? nil : notes.trimmed,
            createdAt: Date()
        )

        Task {
            do {
                if let paymentId = editingPaymentId {
                    try await firestoreService.update(
                        payment,
                        id: paymentId,
                        in: "payments"
                    )
                } else {
                    _ = try await firestoreService.create(
                        payment,
                        in: "payments"
                    )
                }
                didSave = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    private func autoFillFromLease() {
        guard tenantId.isNotEmpty, propertyId.isNotEmpty else {
            if tenantId.isEmpty && propertyId.isEmpty { activeLease = nil }
            return
        }
        let found = leases.first {
            $0.status == .active
            && $0.tenantId == tenantId
            && $0.propertyId == propertyId
        }
        activeLease = found
        guard let lease = found else { return }

        if amount.isEmpty || (Double(amount) ?? 0) == 0 {
            amount = String(format: "%.2f", lease.rentAmount)
        }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.day = min(lease.billingDay, 28)
        if let thisMonth = calendar.date(from: components), thisMonth >= Date() {
            dueDate = thisMonth
        } else if let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) {
            var futureComponents = calendar.dateComponents([.year, .month], from: nextMonth)
            futureComponents.day = min(lease.billingDay, 28)
            dueDate = calendar.date(from: futureComponents) ?? Date()
        }
    }
}
