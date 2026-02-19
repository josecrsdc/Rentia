import FirebaseAuth
import Foundation

#if DEBUG
final class DataSeeder {
    private let firestoreService = FirestoreService()
    // swiftlint:disable function_body_length
    func seed() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            // MARK: - Properties

            let prop1Id = try await firestoreService.create(
                Property(
                    ownerId: userId,
                    name: "Apartamento Centro",
                    address: "Calle Mayor 15, 2B, Madrid",
                    type: .apartment,
                    monthlyRent: 950,
                    currency: "EUR",
                    status: .rented,
                    description: "Apartamento luminoso en el centro con vistas a la plaza",
                    rooms: 3,
                    bathrooms: 2,
                    area: 85,
                    imageURLs: [],
                    createdAt: Date()
                ),
                in: "properties"
            )

            let prop2Id = try await firestoreService.create(
                Property(
                    ownerId: userId,
                    name: "Casa Suburbia",
                    address: "Av. de los Pinos 42, Valencia",
                    type: .house,
                    monthlyRent: 1200,
                    currency: "EUR",
                    status: .available,
                    description: "Casa con jardin y garaje",
                    rooms: 4,
                    bathrooms: 3,
                    area: 150,
                    imageURLs: [],
                    createdAt: Date()
                ),
                in: "properties"
            )

            let prop3Id = try await firestoreService.create(
                Property(
                    ownerId: userId,
                    name: "Local Comercial",
                    address: "Gran Via 88, Bajo, Barcelona",
                    type: .commercial,
                    monthlyRent: 2500,
                    currency: "EUR",
                    status: .rented,
                    description: "Local en zona comercial de alto trafico",
                    rooms: 1,
                    bathrooms: 1,
                    area: 120,
                    imageURLs: [],
                    createdAt: Date()
                ),
                in: "properties"
            )

            let prop4Id = try await firestoreService.create(
                Property(
                    ownerId: userId,
                    name: "Plaza de Garaje Centro",
                    address: "Calle Estudiantes 7, Sevilla",
                    type: .garage,
                    monthlyRent: 350,
                    currency: "EUR",
                    status: .maintenance,
                    description: "Plaza de garaje amplia cerca de la universidad",
                    rooms: 0,
                    bathrooms: 0,
                    area: 18,
                    imageURLs: [],
                    createdAt: Date()
                ),
                in: "properties"
            )

            let prop5Id = try await firestoreService.create(
                Property(
                    ownerId: userId,
                    name: "Terreno en la Sierra",
                    address: "Camino del Pinar, Segovia",
                    type: .land,
                    monthlyRent: 600,
                    currency: "EUR",
                    status: .available,
                    description: "Terreno rustico con acceso directo por camino",
                    rooms: 0,
                    bathrooms: 0,
                    area: 1200,
                    imageURLs: [],
                    createdAt: Date()
                ),
                in: "properties"
            )

            // MARK: - Tenants

            let tenant1Id = try await firestoreService.create(
                Tenant(
                    ownerId: userId,
                    propertyIds: [prop1Id],
                    firstName: "Maria",
                    lastName: "Garcia Lopez",
                    email: "maria.garcia@email.com",
                    phone: "+34 612 345 678",
                    idNumber: "12345678A",
                    leaseStartDate: Calendar.current.date(
                        byAdding: .month, value: -6, to: Date()
                    ),
                    leaseEndDate: Calendar.current.date(
                        byAdding: .month, value: 6, to: Date()
                    ),
                    monthlyRent: 950,
                    depositAmount: 1900,
                    status: .active,
                    createdAt: Date()
                ),
                in: "tenants"
            )

            let tenant2Id = try await firestoreService.create(
                Tenant(
                    ownerId: userId,
                    propertyIds: [prop3Id],
                    firstName: "Carlos",
                    lastName: "Martinez Ruiz",
                    email: "carlos.martinez@empresa.com",
                    phone: "+34 698 765 432",
                    idNumber: "87654321B",
                    leaseStartDate: Calendar.current.date(
                        byAdding: .month, value: -3, to: Date()
                    ),
                    leaseEndDate: Calendar.current.date(
                        byAdding: .year, value: 2, to: Date()
                    ),
                    monthlyRent: 2500,
                    depositAmount: 5000,
                    status: .active,
                    createdAt: Date()
                ),
                in: "tenants"
            )

            _ = try await firestoreService.create(
                Tenant(
                    ownerId: userId,
                    propertyIds: [],
                    firstName: "Ana",
                    lastName: "Fernandez Diaz",
                    email: "ana.fernandez@email.com",
                    phone: "+34 655 111 222",
                    idNumber: "11223344C",
                    leaseStartDate: Calendar.current.date(
                        byAdding: .year, value: -1, to: Date()
                    ),
                    leaseEndDate: Calendar.current.date(
                        byAdding: .month, value: -1, to: Date()
                    ),
                    monthlyRent: 350,
                    depositAmount: 700,
                    status: .inactive,
                    createdAt: Date()
                ),
                in: "tenants"
            )

            // MARK: - Payments

            let calendar = Calendar.current

            // Maria - 6 months of payments for prop1
            for monthOffset in (1...6).reversed() {
                let paymentDate = calendar.date(
                    byAdding: .month, value: -monthOffset, to: Date()
                ) ?? Date()
                let dueDate = calendar.date(
                    byAdding: .day, value: -5, to: paymentDate
                ) ?? Date()

                _ = try await firestoreService.create(
                    Payment(
                        ownerId: userId,
                        tenantId: tenant1Id,
                        propertyId: prop1Id,
                        amount: 950,
                        date: paymentDate,
                        dueDate: dueDate,
                        status: .paid,
                        paymentMethod: "Transferencia bancaria",
                        notes: nil,
                        createdAt: Date()
                    ),
                    in: "payments"
                )
            }

            // Maria - current month pending
            _ = try await firestoreService.create(
                Payment(
                    ownerId: userId,
                    tenantId: tenant1Id,
                    propertyId: prop1Id,
                    amount: 950,
                    date: Date(),
                    dueDate: calendar.date(
                        byAdding: .day, value: 5, to: Date()
                    ) ?? Date(),
                    status: .pending,
                    paymentMethod: nil,
                    notes: "Pendiente de cobro",
                    createdAt: Date()
                ),
                in: "payments"
            )

            // Carlos - 3 months paid + 1 overdue
            for monthOffset in (1...3).reversed() {
                let paymentDate = calendar.date(
                    byAdding: .month, value: -monthOffset, to: Date()
                ) ?? Date()

                _ = try await firestoreService.create(
                    Payment(
                        ownerId: userId,
                        tenantId: tenant2Id,
                        propertyId: prop3Id,
                        amount: 2500,
                        date: paymentDate,
                        dueDate: paymentDate,
                        status: .paid,
                        paymentMethod: "Domiciliacion bancaria",
                        notes: nil,
                        createdAt: Date()
                    ),
                    in: "payments"
                )
            }

            _ = try await firestoreService.create(
                Payment(
                    ownerId: userId,
                    tenantId: tenant2Id,
                    propertyId: prop3Id,
                    amount: 2500,
                    date: Date(),
                    dueDate: calendar.date(
                        byAdding: .day, value: -3, to: Date()
                    ) ?? Date(),
                    status: .overdue,
                    paymentMethod: nil,
                    notes: String(localized: "payments.notes.contact_tenant"),
                    createdAt: Date()
                ),
                in: "payments"
            )

            // Carlos - partial payment for prop4 (old)
            _ = try await firestoreService.create(
                Payment(
                    ownerId: userId,
                    tenantId: tenant2Id,
                    propertyId: prop4Id,
                    amount: 175,
                    date: calendar.date(
                        byAdding: .month, value: -2, to: Date()
                    ) ?? Date(),
                    dueDate: calendar.date(
                        byAdding: .month, value: -2, to: Date()
                    ) ?? Date(),
                    status: .partial,
                    paymentMethod: "Bizum",
                    notes: "Pago parcial, pendiente 175 EUR",
                    createdAt: Date()
                ),
                in: "payments"
            )

            print("[DataSeeder] Dummy data created successfully")
        } catch {
            print("[DataSeeder] Error: \(error.localizedDescription)")
        }
    }

    func deleteAll() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            let properties: [Property] = try await firestoreService.readAll(
                from: "properties",
                whereField: "ownerId",
                isEqualTo: userId
            )
            let tenants: [Tenant] = try await firestoreService.readAll(
                from: "tenants",
                whereField: "ownerId",
                isEqualTo: userId
            )
            let payments: [Payment] = try await firestoreService.readAll(
                from: "payments",
                whereField: "ownerId",
                isEqualTo: userId
            )

            for property in properties {
                if let id = property.id {
                    try await firestoreService.delete(id: id, from: "properties")
                }
            }
            for tenant in tenants {
                if let id = tenant.id {
                    try await firestoreService.delete(id: id, from: "tenants")
                }
            }
            for payment in payments {
                if let id = payment.id {
                    try await firestoreService.delete(id: id, from: "payments")
                }
            }

            print("[DataSeeder] All data deleted successfully")
        } catch {
            print("[DataSeeder] Error deleting: \(error.localizedDescription)")
        }
    }
}
#endif
