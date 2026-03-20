import FirebaseAuth
import FirebaseFirestore
import MapKit
import PhotosUI
import SwiftUI

struct PropertyDetailView: View {
    let propertyId: String
    @State private var property: Property?
    @State private var tenants: [Tenant] = []
    @State private var activeLease: Lease?
    @State private var pastLeases: [Lease] = []
    @State private var administrator: Administrator?
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isUploadingPhoto = false
    @State private var fullScreenPhotoURL: IdentifiableString?
    @State private var photoToDelete: String?
    @State private var showPhotoDeleteConfirmation = false
    @State private var uploadErrorMessage: String?
    @State private var showUploadError = false
    @Environment(\.dismiss) private var dismiss

    private let firestoreService = FirestoreService()
    private let storageService: any StorageServiceProtocol = SupabaseStorageService()

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
                    Text("common.edit")
                }
            }
        }
        .onAppear { loadProperty() }
        .alert("properties.delete.title",
            isPresented: $showDeleteConfirmation
        ) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                deleteProperty()
            }
        } message: {
            Text("properties.delete.confirmation.message")
        }
    }

    private func propertyContent(_ property: Property) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                propertyHeader(property)
                if property.address.hasCoordinates {
                    miniMap(property)
                }
                propertyDetails(property)
                if administrator != nil {
                    administratorSection
                }
                leaseSection(property)
                if !pastLeases.isEmpty {
                    leaseHistorySection(property)
                }
                paymentsSection
                expensesSection
                profitabilitySection(property)
                photosSection(property)
                documentsSection
                propertyStats(property)
                deleteButton
            }
            .padding(AppSpacing.medium)
        }
        .navigationDestination(for: ExpenseDestination.self) { destination in
            switch destination {
            case .list(let id): ExpenseListView(propertyId: id)
            case .detail(let id): ExpenseDetailView(expenseId: id)
            }
        }
        .navigationDestination(for: ReportDestination.self) { destination in
            switch destination {
            case .annual: AnnualReportView()
            case .debt: DebtReportView()
            case .profitability(let id, let name): ProfitabilityView(propertyId: id, propertyName: name)
            }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: max(1, 10 - property.imageURLs.count),
            matching: .images
        )
        .onChange(of: selectedPhotoItems) { uploadSelectedPhotos(for: property) }
        .fullScreenCover(item: $fullScreenPhotoURL) { wrapper in
            FullScreenPhotoView(
                url: wrapper.value,
                onDelete: {
                    photoToDelete = wrapper.value
                    showPhotoDeleteConfirmation = true
                }
            )
        }
        .alert("properties.photos.delete.title", isPresented: $showPhotoDeleteConfirmation) {
            Button("common.cancel", role: .cancel) { photoToDelete = nil }
            Button("common.delete", role: .destructive) {
                if let url = photoToDelete { deletePhoto(url: url) }
            }
        } message: {
            Text("properties.photos.delete.message")
        }
        .alert("common.error", isPresented: $showUploadError) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(uploadErrorMessage ?? "")
        }
    }

    @State private var showPhotosPicker = false

    private func propertyHeader(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                propertyIcon(property)

                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text(property.name)
                        .font(AppTypography.title2)

                    Text(property.address.formattedAddress)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
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

    private func miniMap(_ property: Property) -> some View {
        let coordinate = CLLocationCoordinate2D(
            latitude: property.address.latitude ?? 0,
            longitude: property.address.longitude ?? 0
        )
        return Map(initialPosition: .region(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
        )) {
            Marker(property.name, coordinate: coordinate)
                .tint(AppTheme.Colors.primary)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .allowsHitTesting(false)
    }

    private func propertyDetails(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("properties.details")
                .font(AppTypography.title3)

            if let description = property.description, !description.isEmpty {
                Text(description)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            detailRow(
                icon: "tag",
                label: "properties.detail.type",
                value: property.type.localizedName
            )

            detailRow(
                icon: "circle.fill",
                label: "properties.detail.status",
                value: activeLease != nil
                    ? "properties.status.rented"
                    : property.status.localizedName
            )

            if let ref = property.cadastralReference, !ref.isEmpty {
                detailRow(
                    icon: "number",
                    label: "properties.cadastral_reference",
                    value: LocalizedStringKey(ref)
                )
            }

            if let area = property.area {
                detailRow(
                    icon: "square.dashed",
                    label: "properties.area",
                    value: "\(Int(area)) m²"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Administrator Section

    @State private var showAdministratorActions = false

    private var administratorSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("properties.administrator")
                .font(AppTypography.title3)

            if let administrator {
                Button {
                    showAdministratorActions = true
                } label: {
                    HStack(spacing: AppSpacing.medium) {
                        Text(administrator.initials)
                            .font(AppTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.Colors.secondary)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(administrator.name)
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.Colors.textPrimary)

                            Text(administrator.phone)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)

                            Text(administrator.email)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    administrator.name,
                    isPresented: $showAdministratorActions,
                    titleVisibility: .visible
                ) {
                    administratorActionButtons(administrator)
                }
                .navigationDestination(isPresented: $navigateToAdministrator) {
                    AdministratorDetailView(administratorId: administrator.id ?? "")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @State private var navigateToAdministrator = false

    @ViewBuilder
    private func administratorActionButtons(_ administrator: Administrator) -> some View {
        Button {
            navigateToAdministrator = true
        } label: {
            Label(
                String(localized: "administrators.view_detail"),
                systemImage: "person.badge.key"
            )
        }

        Button {
            openURL("tel:\(administrator.phone.replacingOccurrences(of: " ", with: ""))")
        } label: {
            Label(
                String(localized: "administrators.call_mobile") + " " + administrator.phone,
                systemImage: "phone"
            )
        }

        if let landline = administrator.landlinePhone, !landline.isEmpty {
            Button {
                openURL("tel:\(landline.replacingOccurrences(of: " ", with: ""))")
            } label: {
                Label(
                    String(localized: "administrators.call_landline") + " " + landline,
                    systemImage: "phone.fill"
                )
            }
        }

        Button {
            openURL("mailto:\(administrator.email)")
        } label: {
            Label(
                String(localized: "administrators.send_email") + " " + administrator.email,
                systemImage: "envelope"
            )
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Lease Section

    private func leaseSection(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            if let activeLease {
                Text("leases.active_contract")
                    .font(AppTypography.title3)

                NavigationLink(
                    value: LeaseDestination.detail(activeLease.id ?? "")
                ) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "doc.text")
                            .font(.title3)
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.Colors.primary.opacity(0.1))
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: AppTheme.CornerRadius.small
                                )
                            )

                        VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                            Text(
                                activeLease.rentAmount.formatted(
                                    .currency(code: property.currency)
                                )
                            )
                            .font(AppTypography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                            HStack(spacing: AppSpacing.extraSmall) {
                                Text(activeLease.startDate.formatted(
                                    date: .abbreviated, time: .omitted
                                ))
                                Text("—")
                                if let endDate = activeLease.endDate {
                                    Text(endDate.formatted(
                                        date: .abbreviated, time: .omitted
                                    ))
                                } else {
                                    Text("leases.indefinite")
                                }
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(activeLease.status.localizedName)
                            .font(AppTypography.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, AppSpacing.small)
                            .padding(.vertical, AppSpacing.extraSmall)
                            .background(AppTheme.Colors.success.opacity(0.15))
                            .foregroundStyle(AppTheme.Colors.success)
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textLight)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("leases.no_active_contract")
                    .font(AppTypography.title3)

                NavigationLink(
                    value: LeaseDestination.formForProperty(propertyId)
                ) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("leases.create_contract")
                    }
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.medium)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Lease History

    private func leaseHistorySection(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("leases.history")
                .font(AppTypography.title3)

            ForEach(pastLeases) { lease in
                NavigationLink(
                    value: LeaseDestination.detail(lease.id ?? "")
                ) {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(
                                lease.rentAmount.formatted(
                                    .currency(code: property.currency)
                                )
                            )
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                            HStack(spacing: AppSpacing.extraSmall) {
                                Text(lease.startDate.formatted(
                                    date: .abbreviated, time: .omitted
                                ))
                                Text("—")
                                if let endDate = lease.endDate {
                                    Text(endDate.formatted(
                                        date: .abbreviated, time: .omitted
                                    ))
                                } else {
                                    Text("leases.indefinite")
                                }
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Text(lease.status.localizedName)
                            .font(AppTypography.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, AppSpacing.small)
                            .padding(.vertical, AppSpacing.extraSmall)
                            .background(leaseStatusColor(lease.status).opacity(0.15))
                            .foregroundStyle(leaseStatusColor(lease.status))
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.textLight)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func leaseStatusColor(_ status: LeaseStatus) -> Color {
        switch status {
        case .active: AppTheme.Colors.success
        case .draft: AppTheme.Colors.warning
        case .expired: AppTheme.Colors.error
        case .ended: AppTheme.Colors.textSecondary
        }
    }

    // MARK: - Tenants Section

    private var tenantsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("tabs.tenants")
                .font(AppTypography.title3)

            if tenants.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "person.2.slash")
                        .foregroundStyle(AppTheme.Colors.textLight)

                    Text("properties.no_assigned_tenants")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            } else {
                ForEach(tenants) { tenant in
                    NavigationLink(
                        value: TenantDestination.detail(tenant.id ?? "")
                    ) {
                        tenantRow(tenant)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func tenantRow(_ tenant: Tenant) -> some View {
        HStack(spacing: AppSpacing.small) {
            Text(initials(for: tenant))
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(AppTheme.Colors.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(tenant.fullName)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(tenant.email)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

                    Text(tenant.status.localizedName)
                        .font(AppTypography.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.extraSmall)
                .background(
                    tenant.status == .active
                        ? AppTheme.Colors.success.opacity(0.15)
                        : AppTheme.Colors.textSecondary.opacity(0.15)
                )
                .foregroundStyle(
                    tenant.status == .active
                        ? AppTheme.Colors.success
                        : AppTheme.Colors.textSecondary
                )
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.textLight)
        }
    }

    // MARK: - Photos Section

    private func photosSection(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("properties.photos")
                    .font(AppTypography.title3)

                Spacer()

                if isUploadingPhoto {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if property.imageURLs.count < 10 {
                    Button {
                        showPhotosPicker = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                            .foregroundStyle(AppTheme.Colors.primary)
                    }
                }
            }

            if property.imageURLs.isEmpty {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "photo.slash")
                        .foregroundStyle(AppTheme.Colors.textLight)

                    Text("properties.photos.empty")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.small) {
                        ForEach(property.imageURLs, id: \.self) { url in
                            photoThumbnail(url: url)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func photoThumbnail(url: String) -> some View {
        Button {
            fullScreenPhotoURL = IdentifiableString(url)
        } label: {
            AsyncImage(url: URL(string: url)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay { ProgressView() }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        }
        .buttonStyle(.plain)
    }

    private func uploadSelectedPhotos(for property: Property) {
        guard !selectedPhotoItems.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isUploadingPhoto = true

        Task {
            do {
                var updatedURLs = property.imageURLs
                for item in selectedPhotoItems {
                    guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                    guard let image = UIImage(data: data) else { continue }
                    let path = "owners/\(userId)/properties/\(propertyId)/\(UUID().uuidString).jpg"
                    let url = try await storageService.uploadImage(image, path: path)
                    updatedURLs.append(url)
                }
                selectedPhotoItems = []
                var updatedProperty = property
                updatedProperty.imageURLs = updatedURLs
                try await firestoreService.update(updatedProperty, id: propertyId, in: "properties")
                self.property = updatedProperty
            } catch {
                uploadErrorMessage = error.localizedDescription
                showUploadError = true
                selectedPhotoItems = []
            }
            isUploadingPhoto = false
        }
    }

    private func deletePhoto(url: String) {
        guard var updatedProperty = property else { return }

        Task {
            try? await storageService.delete(url: url)
            updatedProperty.imageURLs.removeAll { $0 == url }
            try? await firestoreService.update(updatedProperty, id: propertyId, in: "properties")
            property = updatedProperty
            photoToDelete = nil
        }
    }

    // MARK: - Expenses Section

    private var expensesSection: some View {
        NavigationLink(value: ExpenseDestination.list(propertyId)) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "eurosign.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.error)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text("expenses.title")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("expenses.view_all")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Documents Section

    private var documentsSection: some View {
        DocumentListView(entityId: propertyId, entityType: .property)
    }

    // MARK: - Profitability Section

    private func profitabilitySection(_ property: Property) -> some View {
        NavigationLink(value: ReportDestination.profitability(propertyId, property.name)) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.success)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.success.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text("reports.profitability")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("reports.view_profitability")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Payments Section

    private var paymentsSection: some View {
        NavigationLink(value: PropertyDestination.payments(propertyId)) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "creditcard")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.CornerRadius.small
                        )
                    )

                VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                    Text("tabs.payments")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("properties.view_payments")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.textLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private func detailRow(
        icon: String,
        label: LocalizedStringKey,
        value: LocalizedStringKey
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
        if property.type.supportsRoomsBathrooms {
            return AnyView(
                HStack(spacing: AppSpacing.medium) {
                    StatCard(
                        title: "properties.rooms",
                        value: "\(property.rooms)",
                        icon: "bed.double",
                        color: AppTheme.Colors.primary
                    )

                    StatCard(
                        title: "properties.bathrooms",
                        value: "\(property.bathrooms)",
                        icon: "shower",
                        color: AppTheme.Colors.secondary
                    )
                }
            )
        }

        let areaValue = property.area.map { "\(Int($0)) m²" } ?? "—"
        return AnyView(
            HStack(spacing: AppSpacing.medium) {
                StatCard(
                    title: "properties.area",
                    value: areaValue,
                    icon: "square.dashed",
                    color: AppTheme.Colors.primary
                )
            }
        )
    }

    private func initials(for tenant: Tenant) -> String {
        let first = tenant.firstName.prefix(1).uppercased()
        let last = tenant.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("properties.delete.title")
            }
            .font(AppTypography.body)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.medium)
            .background(AppTheme.Colors.error.opacity(0.1))
            .foregroundStyle(AppTheme.Colors.error)
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
            )
        }
    }

    private func deleteProperty() {
        Task {
            do {
                try await firestoreService.delete(
                    id: propertyId,
                    from: "properties"
                )
                dismiss()
            } catch {
                // Handle error
            }
        }
    }

    private func loadProperty() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                let loadedProperty: Property = try await firestoreService.read(
                    id: propertyId,
                    from: "properties"
                )
                property = loadedProperty

                if let adminId = loadedProperty.administratorId {
                    administrator = try? await firestoreService.read(
                        id: adminId,
                        from: "administrators"
                    )
                }
            } catch {
                // Handle error
            }

            tenants = (
                try? await firestoreService.readAll(
                    from: "tenants",
                    whereField: "propertyIds",
                    arrayContains: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            let allLeases: [Lease] = (
                try? await firestoreService.readAll(
                    from: "leases",
                    whereField: "propertyId",
                    isEqualTo: propertyId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []
            activeLease = allLeases.first { $0.status == .active }
            pastLeases = allLeases
                .filter { $0.status != .active }
                .sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }

            isLoading = false
        }
    }
}
