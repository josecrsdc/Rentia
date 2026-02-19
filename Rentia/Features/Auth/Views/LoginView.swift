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
        .alert(
            String(localized: "Error"),
            isPresented: Binding(
                get: { viewModel?.showError ?? false },
                set: { viewModel?.showError = $0 }
            )
        ) {
            Button(String(localized: "Aceptar"), role: .cancel) {}
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

            Text("Rentia")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppTheme.Colors.primary)

            Text(String(localized: "Gestiona tus propiedades de forma inteligente"))
                .font(AppTypography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Sign In Buttons

    private var signInButtons: some View {
        VStack(spacing: AppSpacing.medium) {
            SocialSignInButton(
                title: String(localized: "Continuar con Google"),
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
        Text(String(localized: "Al continuar, aceptas nuestros Terminos de Servicio y Politica de Privacidad"))
            .font(AppTypography.caption)
            .foregroundStyle(AppTheme.Colors.textLight)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.extraLarge)
    }
}
