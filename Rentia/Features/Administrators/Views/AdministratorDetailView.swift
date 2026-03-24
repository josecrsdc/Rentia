import FirebaseAuth
import SwiftUI

struct AdministratorDetailView: View {
    let administratorId: String
    @State private var administrator: Administrator?
    @State private var managedProperties: [Property] = []
    @State private var isLoading = true
    @Environment(\.dismiss)
    private var dismiss

    private let firestoreService = FirestoreService()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let administrator {
                administratorContent(administrator)
            }
        }
        .navigationTitle(administrator?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(
                    value: AdministratorDestination.form(administratorId)
                ) {
                    Text("common.edit")
                }
            }
        }
        .onAppear { loadAdministrator() }
    }

    private func administratorContent(_ administrator: Administrator) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                administratorHeader(administrator)
                contactSection(administrator)
                propertiesSection
            }
            .padding(AppSpacing.medium)
        }
    }

    private func administratorHeader(_ administrator: Administrator) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Text(administrator.initials)
                .font(AppTypography.title2)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(AppTheme.Colors.secondary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                Text(administrator.name)
                    .font(AppTypography.title2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func contactSection(_ administrator: Administrator) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("tenants.contact")
                .font(AppTypography.title3)

            tappableRow(
                icon: "phone",
                label: "administrators.phone",
                value: administrator.phone,
                url: "tel:\(administrator.phone.replacingOccurrences(of: " ", with: ""))"
            )

            if let landline = administrator.landlinePhone, !landline.isEmpty {
                tappableRow(
                    icon: "phone.fill",
                    label: "administrators.landline_phone",
                    value: landline,
                    url: "tel:\(landline.replacingOccurrences(of: " ", with: ""))"
                )
            }

            tappableRow(
                icon: "envelope",
                label: "administrators.email",
                value: administrator.email,
                url: "mailto:\(administrator.email)"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("administrators.managed_properties")
                .font(AppTypography.title3)

            if managedProperties.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "building.2.slash")
                        .foregroundStyle(AppTheme.Colors.textLight)

                    Text("administrators.no_properties")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            } else {
                ForEach(managedProperties) { property in
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: property.type.icon)
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(property.name)
                                .font(AppTypography.body)

                            Text(property.address.formattedShort)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func tappableRow(
        icon: String,
        label: LocalizedStringKey,
        value: String,
        url: String
    ) -> some View {
        Button {
            guard let url = URL(string: url) else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 24)

                Text(label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Spacer()

                Text(value)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    private func loadAdministrator() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                administrator = try await firestoreService.read(
                    id: administratorId,
                    from: "administrators"
                )
            } catch {
                // Handle error
            }

            managedProperties = (
                try? await firestoreService.readAll(
                    from: "properties",
                    whereField: "administratorId",
                    isEqualTo: administratorId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            isLoading = false
        }
    }
}
