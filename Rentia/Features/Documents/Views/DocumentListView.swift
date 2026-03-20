import FirebaseAuth
import SwiftUI

struct DocumentListView: View {
    let entityId: String
    let entityType: AssociatedEntityType
    @State private var documents: [RentiaDocument] = []
    @State private var isLoading = false
    @State private var showFilePicker = false
    @State private var showDeleteConfirmation = false
    @State private var documentToDelete: RentiaDocument?
    @State private var errorMessage: String?
    @State private var showError = false

    private let firestoreService = FirestoreService()
    private let storageService: any StorageServiceProtocol = SupabaseStorageService()

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            sectionHeader

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.medium)
            } else if documents.isEmpty {
                emptyState
            } else {
                documentsList
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .task { loadDocuments() }
        .sheet(isPresented: $showFilePicker) {
            DocumentPickerView { url, name in
                uploadDocument(url: url, name: name)
            }
        }
        .alert("documents.delete.title", isPresented: $showDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                if let doc = documentToDelete { deleteDocument(doc) }
            }
        } message: {
            Text("documents.delete.confirmation.message")
        }
        .alert("common.error", isPresented: $showError) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text("documents.title")
                .font(AppTypography.title3)

            Spacer()

            Button {
                showFilePicker = true
            } label: {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .accessibilityLabel(Text("documents.add"))
        }
    }

    private var emptyState: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "doc.slash")
                .foregroundStyle(AppTheme.Colors.textLight)
                .accessibilityHidden(true)

            Text("documents.empty")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    private var documentsList: some View {
        ForEach(documents) { document in
            documentRow(document)
        }
    }

    private func documentRow(_ document: RentiaDocument) -> some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: document.type.icon)
                .font(.title3)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(width: 36, height: 36)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(document.type.localizedName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Button {
                openDocument(document)
            } label: {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .accessibilityLabel(Text("documents.accessibility.open"))

            Button(role: .destructive) {
                documentToDelete = document
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(AppTheme.Colors.error)
            }
            .accessibilityLabel(Text("documents.delete.title"))
        }
    }

    private func loadDocuments() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            documents = (
                try? await firestoreService.readAll(
                    from: "documents",
                    whereField: "associatedEntityId",
                    isEqualTo: entityId,
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []
            documents.sort { $0.createdAt > $1.createdAt }
            isLoading = false
        }
    }

    private func uploadDocument(url: URL, name: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        Task {
            do {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }

                let data = try Data(contentsOf: url)
                let ext = url.pathExtension.isEmpty ? "pdf" : url.pathExtension
                let path = "owners/\(userId)/documents/\(UUID().uuidString).\(ext)"
                let contentType = ext == "pdf" ? "application/pdf" : "image/\(ext)"
                let fileURL = try await storageService.uploadData(
                    data,
                    path: path,
                    contentType: contentType
                )

                let document = RentiaDocument(
                    ownerId: userId,
                    name: name,
                    type: .other,
                    fileURL: fileURL,
                    associatedEntityId: entityId,
                    associatedEntityType: entityType,
                    createdAt: Date()
                )
                _ = try await firestoreService.create(document, in: "documents")
                loadDocuments()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }

    private func deleteDocument(_ document: RentiaDocument) {
        guard let id = document.id else { return }

        Task {
            // Best-effort Storage delete (blob may already be gone)
            try? await storageService.delete(url: document.fileURL)
            do {
                try await firestoreService.delete(id: id, from: "documents")
                documents.removeAll { $0.id == id }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func openDocument(_ document: RentiaDocument) {
        guard let url = URL(string: document.fileURL) else { return }
        UIApplication.shared.open(url)
    }
}
