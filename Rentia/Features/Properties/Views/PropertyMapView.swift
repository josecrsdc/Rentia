import MapKit
import SwiftUI

struct PropertyMapView: View {
    let properties: [Property]
    let leases: [Lease]
    @State private var selectedPropertyId: String?

    private var locatedProperties: [Property] {
        properties.filter { $0.id != nil && $0.address.hasCoordinates }
    }

    var body: some View {
        if locatedProperties.isEmpty {
            emptyState
        } else {
            mapContent
                .navigationDestination(item: $selectedPropertyId) { id in
                    PropertyDetailView(propertyId: id)
                }
        }
    }

    private var mapContent: some View {
        Map {
            ForEach(locatedProperties) { property in
                if let lat = property.address.latitude,
                   let lon = property.address.longitude {
                    Annotation(
                        property.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: lat,
                            longitude: lon
                        )
                    ) {
                        Button {
                            selectedPropertyId = property.id
                        } label: {
                            annotationView(for: property)
                        }
                    }
                }
            }
        }
        .mapStyle(.standard)
    }

    private func annotationView(for property: Property) -> some View {
        Image(systemName: property.type.icon)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(annotationColor(for: property))
            .clipShape(Circle())
            .shadow(radius: 2)
    }

    private func annotationColor(for property: Property) -> Color {
        if isRented(property) {
            return AppTheme.Colors.primary
        }
        switch property.status {
        case .available: return AppTheme.Colors.success
        case .maintenance: return AppTheme.Colors.warning
        }
    }

    private func isRented(_ property: Property) -> Bool {
        guard let propertyId = property.id else { return false }
        return leases.contains {
            $0.propertyId == propertyId && $0.status == .active
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "map",
            title: "properties.map.no_coordinates",
            message: "properties.map.no_coordinates.message"
        )
    }
}
