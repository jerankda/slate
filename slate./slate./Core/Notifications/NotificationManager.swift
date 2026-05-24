import Foundation
import UserNotifications

enum NotificationManager {
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleOneHourReminder(for event: Event) async -> Bool {
        let granted = await requestAuthorization()
        guard granted else { return false }

        let fireDate = event.startTimeUTC.addingTimeInterval(-3600)
        guard fireDate > .now else { return false }

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = "Starts in 1 hour" + (event.league.map { " · \($0)" } ?? "")
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(for: event), content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            return false
        }
    }

    static func cancel(for event: Event) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(for: event)])
    }

    static func isScheduled(for event: Event) async -> Bool {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.contains { $0.identifier == identifier(for: event) }
    }

    private static func identifier(for event: Event) -> String {
        "slate.event.\(event.id)"
    }
}
