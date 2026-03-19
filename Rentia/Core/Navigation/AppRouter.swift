import SwiftUI

// MARK: - Tab

enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard
    case properties
    case tenants
    case payments
    case settings

    var id: Int { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .dashboard: "tabs.dashboard"
        case .properties: "tabs.properties"
        case .tenants: "tabs.tenants"
        case .payments: "tabs.payments"
        case .settings: "tabs.settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "house.fill"
        case .properties: "building.2"
        case .tenants: "person.2"
        case .payments: "creditcard"
        case .settings: "gearshape"
        }
    }
}

// MARK: - Navigation Destinations

enum PropertyDestination: Hashable {
    case detail(String)
    case form(String?)
    case payments(String)
}

enum TenantDestination: Hashable {
    case detail(String)
    case form(String?)
}

enum PaymentDestination: Hashable {
    case detail(String)
    case form(String?)
}

enum AdministratorDestination: Hashable {
    case detail(String)
    case form(String?)
    case list
}

enum LeaseDestination: Hashable {
    case detail(String)
    case form(String?)
    case formForProperty(String)
}
