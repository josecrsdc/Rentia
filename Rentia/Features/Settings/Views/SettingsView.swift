import SwiftUI

struct SettingsView: View {
    @Environment(\.container) private var container
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    profileHeader
                    accountSection
                    preferencesLinkSection
                    #if DEBUG
                    debugLinkSection
                    #endif
                    dangerZoneSection
                }
                .padding(AppSpacing.medium)
            }
        }
        .navigationTitle("settings.title")
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel(
                    authService: container.authService
                )
            }
            viewModel?.loadProfile()
        }
        .confirmationDialog("auth.sign_out",
            isPresented: Binding(
                get: { viewModel?.showSignOutConfirmation ?? false },
                set: { viewModel?.showSignOutConfirmation = $0 }
            ),
            titleVisibility: .visible
        ) {
            Button(
                "auth.sign_out",
                role: .destructive
            ) {
                viewModel?.signOut()
            }
        } message: {
            Text("auth.sign_out.confirmation.message")
        }
        .alert("common.error",
            isPresented: Binding(
                get: { viewModel?.showError ?? false },
                set: { viewModel?.showError = $0 }
            )
        ) {
            Button("common.accept", role: .cancel) {}
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: AppSpacing.medium) {
            if let photoURL = viewModel?.photoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }

            VStack(spacing: AppSpacing.extraSmall) {
                Text(viewModel?.displayName ?? "")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(viewModel?.email ?? "")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .foregroundStyle(AppTheme.Colors.primary.opacity(0.3))
    }

    // MARK: - Account Section

    private var accountSection: some View {
        NavigationLink {
            AccountInfoView(viewModel: viewModel)
        } label: {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "person")
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.CornerRadius.small
                        )
                    )

                Text("account.title")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.CornerRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var preferencesLinkSection: some View {
        NavigationLink {
            PreferencesView()
        } label: {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.CornerRadius.small
                        )
                    )

                Text("settings.preferences.title")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.CornerRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
    }

    #if DEBUG
    private var debugLinkSection: some View {
        NavigationLink {
            DebugView()
        } label: {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundStyle(AppTheme.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.Colors.primary.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.CornerRadius.small
                        )
                    )

                Text("common.debug")
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppTheme.CornerRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
    }
    #endif

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Button {
                viewModel?.showSignOutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("auth.sign_out")
                        .font(AppTypography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.Colors.cardBackground)
                .foregroundStyle(AppTheme.Colors.error)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.medium
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: AppTheme.CornerRadius.medium
                    )
                    .stroke(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}
