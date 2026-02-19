import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(\.container) private var container
    @State private var viewModel: LoginViewModel?

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xxLarge) {
                Spacer()

                headerSection

                Spacer()

                signInButtons

                termsText
            }
            .padding(.horizontal, AppSpacing.extraLarge)
            .padding(.bottom, AppSpacing.xxxLarge)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = LoginViewModel(
                    authService: container.authService,
                    authState: container.authState
                )
            }
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.Colors.primary)

            Text("auth.rentia")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primary)

            Text("auth.tagline")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Sign In Buttons

    private var signInButtons: some View {
        VStack(spacing: AppSpacing.medium) {
            SocialSignInButton(
                title: "auth.continue_with_google",
                icon: "globe",
                action: { viewModel?.signInWithGoogle() }
            )

            SignInWithAppleButton(.signIn) { request in
                let nonceData = viewModel?.prepareAppleSignIn()
                request.requestedScopes = [.fullName, .email]
                request.nonce = nonceData?.hashedNonce
            } onCompletion: { result in
                viewModel?.handleAppleSignIn(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

            if viewModel?.isLoading == true {
                ProgressView()
                    .padding(.top, AppSpacing.small)
            }
        }
    }

    // MARK: - Terms

    private var termsText: some View {
        Text("auth.terms_notice")
            .font(AppTypography.caption)
            .foregroundStyle(AppTheme.Colors.textLight)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.extraLarge)
    }
}
