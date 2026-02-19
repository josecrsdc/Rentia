import SwiftUI

@Observable
final class DIContainer {
    let authService: AuthenticationService
    let authState: AuthenticationState

    init(
        authService: AuthenticationService,
        authState: AuthenticationState
    ) {
        self.authService = authService
        self.authState = authState
    }
}

// MARK: - Environment Key

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer(
        authService: FirebaseAuthService(),
        authState: AuthenticationState()
    )
}

extension EnvironmentValues {
    var container: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
