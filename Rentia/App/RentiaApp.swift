import FirebaseAuth
import FirebaseCore
import SwiftUI

@main
struct RentiaApp: App {
    @State private var container: DIContainer
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @State private var fontScaleManager = FontScaleManager()
    @Environment(\.scenePhase) private var scenePhase

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
                .dynamicTypeSize(fontScaleManager.dynamicTypeSize ?? .medium)
                .environment(fontScaleManager)
                .preferredColorScheme(preferredColorScheme)
                .onAppear {
                    container.authState.startListening()
                    Task { await NotificationService.shared.requestAuthorization() }
                }
                .onChange(of: scenePhase) {
                    if scenePhase == .active && container.authState.isAuthenticated {
                        scheduleNotifications()
                    }
                }
        }
    }

    private func scheduleNotifications() {
        Task {
            let firestoreService = FirestoreService()
            guard let userId = container.authState.currentUser?.uid else { return }

            let payments: [Payment] = (
                try? await firestoreService.readAll(
                    from: "payments",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []
            let overdueCount = payments.filter {
                $0.status == .overdue || ($0.status == .pending && $0.dueDate.isOverdue)
            }.count
            await NotificationService.shared.scheduleOverduePaymentsNotification(
                overdueCount: overdueCount
            )

            let leases: [Lease] = (
                try? await firestoreService.readAll(
                    from: "leases",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []
            let properties: [Property] = (
                try? await firestoreService.readAll(
                    from: "properties",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            let expiringLeases = leases
                .filter { $0.status == .active }
                .compactMap { lease -> (id: String, propertyName: String, endDate: Date)? in
                    guard let endDate = lease.endDate,
                          let leaseId = lease.id else { return nil }
                    let name = properties.first { $0.id == lease.propertyId }?.name ?? ""
                    return (id: leaseId, propertyName: name, endDate: endDate)
                }
            await NotificationService.shared.scheduleLeaseExpiryNotifications(
                leases: expiringLeases
            )
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
