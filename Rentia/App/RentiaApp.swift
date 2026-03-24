import FirebaseAuth
import FirebaseCore
import SwiftUI

@main
struct RentiaApp: App {
    @State private var container: DIContainer
    @AppStorage("appearanceMode")
    private var appearanceMode = "system"
    @State private var fontScaleManager = FontScaleManager()
    @Environment(\.scenePhase)
    private var scenePhase

    init() {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.warning)
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
                        syncOverduePayments()
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
            let overdueHour   = UserDefaults.standard.object(forKey: "notifyOverdueHour")   as? Int ?? 9
            let overdueMinute = UserDefaults.standard.object(forKey: "notifyOverdueMinute") as? Int ?? 0
            let notifyOverdue = UserDefaults.standard.object(forKey: "notifyOverduePayments") as? Bool ?? true
            if notifyOverdue {
                await NotificationService.shared.scheduleOverduePaymentsNotification(
                    overdueCount: overdueCount, hour: overdueHour, minute: overdueMinute
                )
            }

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
            let leaseHour     = UserDefaults.standard.object(forKey: "notifyLeaseHour")     as? Int ?? 9
            let leaseMinute   = UserDefaults.standard.object(forKey: "notifyLeaseMinute")   as? Int ?? 0
            let leaseWarning1 = UserDefaults.standard.object(forKey: "notifyLeaseWarning1") as? Int ?? 60
            let leaseWarning2 = UserDefaults.standard.object(forKey: "notifyLeaseWarning2") as? Int ?? 30
            let notifyLease = UserDefaults.standard.object(forKey: "notifyLeaseExpiry") as? Bool ?? true
            if notifyLease {
                await NotificationService.shared.scheduleLeaseExpiryNotifications(
                    leases: expiringLeases,
                    hour: leaseHour,
                    minute: leaseMinute,
                    warningDays: [leaseWarning1, leaseWarning2]
                )
            }
        }
    }

    private func syncOverduePayments() {
        Task {
            let firestoreService = FirestoreService()
            guard let userId = container.authState.currentUser?.uid else { return }

            let pendingPayments: [Payment] = (
                try? await firestoreService.readAll(
                    from: "payments",
                    whereField: "status",
                    isEqualTo: "pending",
                    whereField: "ownerId",
                    isEqualTo: userId
                )
            ) ?? []

            let overdue = pendingPayments.filter { $0.dueDate < Date() }
            for payment in overdue {
                guard let paymentId = payment.id else { continue }
                var updated = payment
                updated.status = .overdue
                try? await firestoreService.update(updated, id: paymentId, in: "payments")
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
