import Foundation

enum WidgetSharedStore {
    static let appGroupIdentifier = "group.com.local.EbbinghausMemory"

    private static let itemsKey = "widgetMemoryItems"

    struct Item: Codable, Identifiable, Equatable {
        var id: UUID
        var listName: String
        var reviewRecords: [ReviewRecord]
    }

    struct ReviewRecord: Codable, Identifiable, Equatable {
        var id: UUID
        var targetDate: Date
        var isCompleted: Bool
    }

    static func saveItems(_ items: [Item]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }

        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: itemsKey)
        } catch {
            print("Failed to save widget items: \(error)")
        }
    }

    static func loadItems() -> [Item] {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = userDefaults.data(forKey: itemsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([Item].self, from: data)
        } catch {
            print("Failed to load widget items: \(error)")
            return []
        }
    }

    static func dueTodayNames(on date: Date = Date(), calendar: Calendar = .current) -> [String] {
        loadItems()
            .filter { item in
                item.reviewRecords.contains { record in
                    !record.isCompleted && calendar.isDate(record.targetDate, inSameDayAs: date)
                }
            }
            .map(\.listName)
    }
}
