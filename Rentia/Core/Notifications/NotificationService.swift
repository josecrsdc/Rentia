import Foundation
import UserNotifications

final class NotificationService: @unchecked Sendable {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleOverduePaymentsNotification(overdueCount: Int, hour: Int = 9, minute: Int = 0) async {
        guard overdueCount > 0 else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: ["overdue_payments"])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notifications.overdue_payments.title")
        content.body = String(
            format: String(localized: "notifications.overdue_payments.body"),
            overdueCount
        )
        content.sound = .default
        content.userInfo = ["type": "overdue_payments"]

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "overdue_payments",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    func scheduleLeaseExpiryNotifications(
        leases: [(id: String, propertyName: String, endDate: Date)],
        hour: Int = 9,
        minute: Int = 0,
        warningDays: [Int] = [60, 30]
    ) async {
        let center = UNUserNotificationCenter.current()
        let existingIds = await center.pendingNotificationRequests().map(\.identifier)
        let leaseIds = leases.flatMap { lease in
            warningDays.map { "lease_expiry_\(lease.id)_\($0)d" }
        }
        let toRemove = existingIds.filter {
            $0.hasPrefix("lease_expiry_") && !leaseIds.contains($0)
        }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)

        for lease in leases {
            for daysBefore in warningDays {
                await scheduleLeaseNotification(
                    id: lease.id,
                    propertyName: lease.propertyName,
                    endDate: lease.endDate,
                    daysBefore: daysBefore,
                    hour: hour,
                    minute: minute
                )
            }
        }
    }

    private func scheduleLeaseNotification(
        id: String,
        propertyName: String,
        endDate: Date,
        daysBefore: Int,
        hour: Int,
        minute: Int
    ) async {
        guard let notifyDate = Calendar.current.date(
            byAdding: .day, value: -daysBefore, to: endDate
        ) else { return }
        guard notifyDate > Date() else { return }

        let daysLeft = Calendar.current.dateComponents(
            [.day], from: Date(), to: endDate
        ).day ?? 0
        guard daysLeft > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notifications.lease_expiring.title")
        content.body = String(
            format: String(localized: "notifications.lease_expiring.body"),
            propertyName,
            daysLeft
        )
        content.sound = .default
        content.userInfo = ["type": "lease_expiry", "leaseId": id]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: notifyDate)
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "lease_expiry_\(id)_\(daysBefore)d",
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
