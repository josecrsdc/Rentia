import MapKit
import SwiftUI

struct AddressSearchView: View {
    @Binding var address: Address
    @State private var viewModel = AddressSearchViewModel()
    @State private var searchText = ""
    @State private var showManualEntry = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            List {
                searchSection
                if !viewModel.results.isEmpty {
                    suggestionsSection
                }
                manualEntrySection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("properties.address.search")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) {
            viewModel.updateQuery(searchText)
        }
    }

    // MARK: - Sections

    private var searchSection: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                TextField(
                    "properties.address.search",
                    text: $searchText
                )
                .textInputAutocapitalization(.words)

                if viewModel.isSearching {
                    ProgressView()
                }
            }
        }
    }

    private var suggestionsSection: some View {
        Section {
            ForEach(viewModel.results, id: \.self) { completion in
                Button {
                    selectCompletion(completion)
                } label: {
                    VStack(alignment: .leading, spacing: AppSpacing.extraSmall) {
                        Text(completion.title)
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.Colors.textPrimary)

                        Text(completion.subtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var manualEntrySection: some View {
        Section(
            header: Text("properties.address.manual_entry"),
            footer: manualEntryFooter
        ) {
            if showManualEntry {
                TextField(
                    "properties.address.street",
                    text: $address.street
                )

                TextField(
                    "properties.address.city",
                    text: $address.city
                )

                TextField(
                    "properties.address.state",
                    text: $address.state
                )

                TextField(
                    "properties.address.postal_code",
                    text: $address.postalCode
                )

                TextField(
                    "properties.address.country",
                    text: $address.country
                )
            } else {
                Button {
                    showManualEntry = true
                } label: {
                    Label(
                        "properties.address.manual_entry",
                        systemImage: "pencil"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var manualEntryFooter: some View {
        if showManualEntry && address.street.isNotEmpty {
            Text(address.formattedAddress)
        }
    }

    // MARK: - Actions

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        Task {
            if let resolved = await viewModel.selectCompletion(completion) {
                address = resolved
                dismiss()
            }
        }
    }
}
