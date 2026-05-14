import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                self?.center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if let error {
                        print("Notification authorization failed: \(error)")
                    }
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    func scheduleNotifications(
        for item: MemoryItem,
        settings: AppSettings,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        guard settings.notificationsEnabled else { return }

        for record in item.reviewRecords
        where !record.isCompleted && scheduledDate(for: record, settings: settings, calendar: calendar) > now {
            scheduleNotification(for: item, record: record, settings: settings, calendar: calendar)
        }
    }

    func rescheduleNotifications(for item: MemoryItem, settings: AppSettings) {
        removeNotifications(for: item)
        scheduleNotifications(for: item, settings: settings)
    }

    func rescheduleNotifications(for items: [MemoryItem], settings: AppSettings) {
        removeNotifications(for: items)
        guard settings.notificationsEnabled else { return }

        for item in items {
            scheduleNotifications(for: item, settings: settings)
        }
    }

    func removeNotifications(for items: [MemoryItem]) {
        let identifiers = items.flatMap { item in
            item.reviewRecords.map {
                Self.identifier(itemID: item.id, recordID: $0.id)
            }
        }

        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removeNotification(itemID: UUID, recordID: UUID) {
        let identifier = Self.identifier(itemID: itemID, recordID: recordID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    func removeNotifications(for item: MemoryItem) {
        let identifiers = item.reviewRecords.map {
            Self.identifier(itemID: item.id, recordID: $0.id)
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func cleanupPastNotifications(for items: [MemoryItem], settings: AppSettings, now: Date = Date()) {
        let identifiers = items.flatMap { item in
            item.reviewRecords
                .filter { scheduledDate(for: $0, settings: settings) <= now }
                .map { Self.identifier(itemID: item.id, recordID: $0.id) }
        }

        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    static func identifier(itemID: UUID, recordID: UUID) -> String {
        "\(itemID.uuidString)-\(recordID.uuidString)"
    }

    private func scheduleNotification(
        for item: MemoryItem,
        record: ReviewRecord,
        settings: AppSettings,
        calendar: Calendar
    ) {
        let content = UNMutableNotificationContent()
        content.title = "复习提醒"
        content.body = "该复习「\(item.listName)」了"
        content.sound = .default

        // Use calendar components instead of a time interval so the system can deliver
        // the notification at the chosen local time even after the app exits.
        var components = calendar.dateComponents([.year, .month, .day], from: record.targetDate)
        components.hour = settings.clampedHour
        components.minute = settings.clampedMinute
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.identifier(itemID: item.id, recordID: record.id),
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func scheduledDate(
        for record: ReviewRecord,
        settings: AppSettings,
        calendar: Calendar = .current
    ) -> Date {
        let targetDay = calendar.startOfDay(for: record.targetDate)
        return calendar.date(
            bySettingHour: settings.clampedHour,
            minute: settings.clampedMinute,
            second: 0,
            of: targetDay
        ) ?? record.targetDate
    }
}
