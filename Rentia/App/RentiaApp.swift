import FirebaseCore
import SwiftUI

@main
struct RentiaApp: App {
    @State private var container: DIContainer
    @AppStorage("appearanceMode") private var appearanceMode = "system"

    init() {
        FirebaseApp.configure()
        let authService = FirebaseAuthService()
        let authState = AuthenticationState()
        _container = State(
            initialValue: DIContainer(
                authService: authService,
                authState: authState
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(\.container, container)
                .preferredColorScheme(preferredColorScheme)
                .onAppear {
                    container.authState.startListening()
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if container.authState.isLoading {
            LoadingView()
        } else if container.authState.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}
