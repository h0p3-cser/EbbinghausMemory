import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    private let userDefaults: UserDefaults
    private let itemsKey = "memoryItems"
    private let groupsKey = "memoryGroups"
    private let completedRecordsKey = "completedMemoryRecords"
    private let settingsKey = "appSettings"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadItems() -> [MemoryItem] {
        load([MemoryItem].self, forKey: itemsKey, fallback: [])
    }

    func saveItems(_ items: [MemoryItem]) {
        save(items, forKey: itemsKey)
    }

    func loadGroups() -> [MemoryGroup] {
        load([MemoryGroup].self, forKey: groupsKey, fallback: [])
    }

    func saveGroups(_ groups: [MemoryGroup]) {
        save(groups, forKey: groupsKey)
    }

    func loadCompletedRecords() -> [CompletedMemoryRecord] {
        load([CompletedMemoryRecord].self, forKey: completedRecordsKey, fallback: [])
    }

    func saveCompletedRecords(_ records: [CompletedMemoryRecord]) {
        save(records, forKey: completedRecordsKey)
    }

    func loadSettings() -> AppSettings {
        load(AppSettings.self, forKey: settingsKey, fallback: .default)
    }

    func saveSettings(_ settings: AppSettings) {
        save(settings, forKey: settingsKey)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String, fallback: T) -> T {
        guard let data = userDefaults.data(forKey: key) else {
            return fallback
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode \(key): \(error)")
            return fallback
        }
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to encode \(key): \(error)")
        }
    }
}
