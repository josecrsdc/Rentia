import SwiftUI

// MARK: - Tab

enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard
    case properties
    case tenants
    case payments
    case profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .dashboard: String(localized: "Inicio")
        case .properties: String(localized: "Propiedades")
        case .tenants: String(localized: "Inquilinos")
        case .payments: String(localized: "Pagos")
        case .profile: String(localized: "Perfil")
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "house.fill"
        case .properties: "building.2"
        case .tenants: "person.2"
        case .payments: "creditcard"
        case .profile: "person.circle"
        }
    }
}

// MARK: - Navigation Destinations

enum PropertyDestination: Hashable {
    case detail(String)
    case form(String?)
}

enum TenantDestination: Hashable {
    case detail(String)
    case form(String?)
}

enum PaymentDestination: Hashable {
    case detail(String)
    case form(String?)
}
