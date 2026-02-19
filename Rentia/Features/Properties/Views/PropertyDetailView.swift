import FirebaseFirestore
import SwiftUI

struct PropertyDetailView: View {
    let propertyId: String
    @State private var property: Property?
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let property {
                propertyContent(property)
            }
        }
        .navigationTitle(property?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(
                    value: PropertyDestination.form(propertyId)
                ) {
                    Text(String(localized: "Editar"))
                }
            }
        }
        .onAppear { loadProperty() }
    }

    private func propertyContent(_ property: Property) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                propertyHeader(property)
                propertyDetails(property)
                propertyStats(property)
            }
            .padding(AppSpacing.medium)
        }
    }

    private func propertyHeader(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                propertyIcon(property)

                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text(property.name)
                        .font(AppTypography.title2)

                    Text(property.address)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Text(
                property.monthlyRent.formatted(
                    .currency(code: property.currency)
                )
            )
            .font(AppTypography.moneyLarge)
            .foregroundStyle(AppTheme.Colors.primary)
            .padding(.top, AppSpacing.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func propertyIcon(_ property: Property) -> some View {
        Image(systemName: property.type.icon)
            .font(.title2)
            .foregroundStyle(AppTheme.Colors.primary)
            .frame(width: 56, height: 56)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.CornerRadius.medium
                )
            )
    }

    private func propertyDetails(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "Detalles"))
                .font(AppTypography.title3)

            if let description = property.description, !description.isEmpty {
                Text(description)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            detailRow(
                icon: "tag",
                label: String(localized: "Tipo"),
                value: property.type.displayName
            )

            detailRow(
                icon: "circle.fill",
                label: String(localized: "Estado"),
                value: property.status.displayName
            )

            if let area = property.area {
                detailRow(
                    icon: "square.dashed",
                    label: String(localized: "Area"),
                    value: "\(Int(area)) m²"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func detailRow(
        icon: String,
        label: String,
        value: String
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(AppTypography.headline)
        }
    }

    private func propertyStats(_ property: Property) -> some View {
        HStack(spacing: AppSpacing.medium) {
            StatCard(
                title: String(localized: "Habitaciones"),
                value: "\(property.rooms)",
                icon: "bed.double",
                color: AppTheme.Colors.primary
            )

            StatCard(
                title: String(localized: "Banos"),
                value: "\(property.bathrooms)",
                icon: "shower",
                color: AppTheme.Colors.secondary
            )
        }
    }

    private func loadProperty() {
        Task {
            do {
                property = try await firestoreService.read(
                    id: propertyId,
                    from: "properties"
                )
            } catch {
                // Handle error
            }
            isLoading = false
        }
    }
}
