import Foundation
import UserNotifications
import Observation

/// App-wide store for local-notification reminders. Backed by `UNUserNotificationCenter` plus a
/// tiny `UserDefaults`-mirrored set so SwiftUI rows can read state synchronously without firing
/// async work for every cell.
@Observable
final class NotificationStore {
    static let shared = NotificationStore()

    private(set) var scheduledEventIds: Set<String> = []
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let defaults = UserDefaults.standard
    private let storageKey = "slate.reminders.eventIds"
    private let leadKey = "slate.reminders.leadMinutes"

    init() {
        if let arr = defaults.array(forKey: storageKey) as? [String] {
            scheduledEventIds = Set(arr)
        }
    }

    func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Re-syncs our local set with the system's pending requests. Call on app launch in case
    /// the user cleared notifications from settings.
    func sync() async {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let ids = Set(pending.compactMap { req -> String? in
            guard req.identifier.hasPrefix("slate.event.") else { return nil }
            return String(req.identifier.dropFirst("slate.event.".count))
        })
        scheduledEventIds = ids
        persist()
        await refreshAuthorization()
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let ok = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorization()
            return ok
        } catch {
            return false
        }
    }

    func leadMinutes(for event: Event) -> Int {
        let key = "\(leadKey).\(event.id)"
        let v = defaults.integer(forKey: key)
        return v > 0 ? v : 60
    }

    @discardableResult
    func schedule(event: Event, leadMinutes: Int) async -> Bool {
        guard await requestAuthorization() else { return false }

        let fireDate = event.startTimeUTC.addingTimeInterval(TimeInterval(-leadMinutes * 60))
        guard fireDate > .now else { return false }

        cancelLocal(eventId: event.id)

        let content = UNMutableNotificationContent()
        content.title = event.title
        let leadCopy = leadString(minutes: leadMinutes)
        content.body = "Starts in \(leadCopy)" + (event.league.map { " · \($0)" } ?? "")
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(for: event.id),
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            scheduledEventIds.insert(event.id)
            defaults.set(leadMinutes, forKey: "\(leadKey).\(event.id)")
            persist()
            return true
        } catch {
            return false
        }
    }

    func cancel(eventId: String) {
        cancelLocal(eventId: eventId)
        scheduledEventIds.remove(eventId)
        defaults.removeObject(forKey: "\(leadKey).\(eventId)")
        persist()
    }

    func clearAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for id in scheduledEventIds {
            defaults.removeObject(forKey: "\(leadKey).\(id)")
        }
        scheduledEventIds.removeAll()
        persist()
    }

    func isScheduled(eventId: String) -> Bool {
        scheduledEventIds.contains(eventId)
    }

    // MARK: - Private

    private func cancelLocal(eventId: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(for: eventId)])
    }

    private func identifier(for eventId: String) -> String {
        "slate.event.\(eventId)"
    }

    private func persist() {
        defaults.set(Array(scheduledEventIds), forKey: storageKey)
    }

    private func leadString(minutes: Int) -> String {
        if minutes % 1440 == 0 { return "\(minutes/1440) day\(minutes/1440 == 1 ? "" : "s")" }
        if minutes % 60 == 0 { return "\(minutes/60) hour\(minutes/60 == 1 ? "" : "s")" }
        return "\(minutes) minutes"
    }
}

/// Preset lead times shown in the EventDetail picker.
enum ReminderLead: Int, CaseIterable, Identifiable {
    case fifteenMin = 15
    case oneHour = 60
    case threeHours = 180
    case oneDay = 1440

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .fifteenMin: return "15 min"
        case .oneHour: return "1 hour"
        case .threeHours: return "3 hours"
        case .oneDay: return "1 day"
        }
    }
}

// Keep the old enum API as a thin shim so anything still calling it compiles.
enum NotificationManager {
    static func requestAuthorization() async -> Bool {
        await NotificationStore.shared.requestAuthorization()
    }
    static func scheduleOneHourReminder(for event: Event) async -> Bool {
        await NotificationStore.shared.schedule(event: event, leadMinutes: 60)
    }
    static func cancel(for event: Event) {
        NotificationStore.shared.cancel(eventId: event.id)
    }
    static func isScheduled(for event: Event) async -> Bool {
        NotificationStore.shared.isScheduled(eventId: event.id)
    }
}
