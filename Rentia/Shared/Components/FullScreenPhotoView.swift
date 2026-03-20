import SwiftUI

struct FullScreenPhotoView: View {
    let url: String
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(Text("properties.photos.accessibility.fullscreen"))
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black.opacity(0.5), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel(Text("common.close"))
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel(Text("properties.photos.delete.title"))
                }
            }
        }
    }
}

// MARK: - Identifiable String Wrapper

struct IdentifiableString: Identifiable {
    let id: String
    var value: String { id }

    init(_ value: String) {
        self.id = value
    }
}
