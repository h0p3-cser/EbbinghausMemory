import AppKit
import Foundation
import WidgetKit

@MainActor
final class MainViewModel: ObservableObject {
    @Published private(set) var items: [MemoryItem]
    @Published private(set) var groups: [MemoryGroup]
    @Published private(set) var completedRecords: [CompletedMemoryRecord]
    @Published private(set) var settings: AppSettings
    @Published var notificationsAllowed = true

    private let persistence: PersistenceController
    private let notificationManager: NotificationManager
    private let calendar: Calendar

    init(
        persistence: PersistenceController = .shared,
        notificationManager: NotificationManager = .shared,
        calendar: Calendar = .current
    ) {
        self.persistence = persistence
        self.notificationManager = notificationManager
        self.calendar = calendar
        self.items = persistence.loadItems()
        self.groups = persistence.loadGroups()
        self.completedRecords = persistence.loadCompletedRecords()
        self.settings = persistence.loadSettings()

        requestNotificationAuthorization()
        archiveCompletedItems()
        cleanupPastNotifications()
        updateDockBadge()
        syncWidgetData()
    }

    var shouldShowNotificationWarning: Bool {
        settings.notificationsEnabled && !notificationsAllowed
    }

    func addItem(listName: String, creationDate: Date, groupID: MemoryGroup.ID? = nil) {
        let trimmedName = listName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let item = MemoryItem(listName: trimmedName, creationDate: creationDate, groupID: groupID)
        items.append(item)
        sortItems()
        persistItems()
        notificationManager.scheduleNotifications(for: item, settings: settings)
        updateDockBadge()
        syncWidgetData()
    }

    func addGroup(name: String, colorName: GroupColorName) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        groups.append(MemoryGroup(name: trimmedName, colorName: colorName))
        groups.sort { $0.creationDate < $1.creationDate }
        persistGroups()
    }

    func items(in groupID: MemoryGroup.ID?) -> [MemoryItem] {
        items
            .filter { $0.groupID == groupID }
            .sorted { $0.creationDate > $1.creationDate }
    }

    func moveItem(_ itemID: MemoryItem.ID, to groupID: MemoryGroup.ID?) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }

        items[index].groupID = groupID
        sortItems()
        persistItems()
        syncWidgetData()
    }

    func deleteGroupAndItems(id: MemoryGroup.ID) {
        let groupItems = items(in: id)
        notificationManager.removeNotifications(for: groupItems)
        items.removeAll { $0.groupID == id }
        groups.removeAll { $0.id == id }
        persistItems()
        persistGroups()
        updateDockBadge()
        syncWidgetData()
    }

    func deleteItem(id: MemoryItem.ID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        notificationManager.removeNotifications(for: item)
        items.removeAll { $0.id == id }
        persistItems()
        updateDockBadge()
        syncWidgetData()
    }

    func updateListName(itemID: MemoryItem.ID, listName: String) {
        let trimmedName = listName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let index = items.firstIndex(where: { $0.id == itemID }) else {
            return
        }

        items[index].listName = trimmedName
        persistItems()
        notificationManager.rescheduleNotifications(for: items[index], settings: settings)
        syncWidgetData()
    }

    func markComplete(itemID: MemoryItem.ID, recordID: ReviewRecord.ID) {
        guard let itemIndex = items.firstIndex(where: { $0.id == itemID }),
              let recordIndex = items[itemIndex].reviewRecords.firstIndex(where: { $0.id == recordID }) else {
            return
        }

        items[itemIndex].reviewRecords[recordIndex].isCompleted = true
        notificationManager.removeNotification(itemID: itemID, recordID: recordID)
        archiveIfCompleted(itemID: itemID)
        persistItems()
        updateDockBadge()
        syncWidgetData()
    }

    func markAllOverdueComplete(itemID: MemoryItem.ID) {
        guard let itemIndex = items.firstIndex(where: { $0.id == itemID }) else { return }

        let overdueRecords = items[itemIndex].reviewRecords.filter {
            $0.isOverdue(calendar: calendar)
        }

        guard !overdueRecords.isEmpty else { return }

        for record in overdueRecords {
            if let recordIndex = items[itemIndex].reviewRecords.firstIndex(where: { $0.id == record.id }) {
                items[itemIndex].reviewRecords[recordIndex].isCompleted = true
                notificationManager.removeNotification(itemID: itemID, recordID: record.id)
            }
        }

        archiveIfCompleted(itemID: itemID)
        persistItems()
        updateDockBadge()
        syncWidgetData()
    }

    func updateNotificationsEnabled(_ isEnabled: Bool) {
        settings.notificationsEnabled = isEnabled
        persistSettings()

        if isEnabled {
            requestNotificationAuthorization {
                self.notificationManager.rescheduleNotifications(for: self.items, settings: self.settings)
            }
        } else {
            notificationManager.removeNotifications(for: items)
        }

        updateDockBadge()
        syncWidgetData()
    }

    func updateNotificationTime(hour: Int, minute: Int) {
        settings.notificationHour = hour
        settings.notificationMinute = minute
        persistSettings()

        if settings.notificationsEnabled {
            notificationManager.rescheduleNotifications(for: items, settings: settings)
        }
    }

    func item(with id: MemoryItem.ID?) -> MemoryItem? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    func todayReviewCount() -> Int {
        items.reduce(0) { partialResult, item in
            partialResult + item.reviewRecords.filter { $0.isDueToday(calendar: calendar) }.count
        }
    }

    private func requestNotificationAuthorization() {
        requestNotificationAuthorization(completion: nil)
    }

    private func requestNotificationAuthorization(completion: (() -> Void)?) {
        notificationManager.requestAuthorization { [weak self] allowed in
            Task { @MainActor in
                self?.notificationsAllowed = allowed
                completion?()
            }
        }
    }

    private func cleanupPastNotifications() {
        notificationManager.cleanupPastNotifications(for: items, settings: settings)
    }

    private func persistItems() {
        persistence.saveItems(items)
    }

    private func persistGroups() {
        persistence.saveGroups(groups)
    }

    private func persistCompletedRecords() {
        persistence.saveCompletedRecords(completedRecords)
    }

    private func persistSettings() {
        persistence.saveSettings(settings)
    }

    private func updateDockBadge() {
        let count = todayReviewCount()
        NSApplication.shared.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
    }

    private func sortItems() {
        items.sort { $0.creationDate > $1.creationDate }
    }

    private func archiveCompletedItems() {
        let completedItems = items.filter { $0.isFullyCompleted() }
        guard !completedItems.isEmpty else { return }

        for item in completedItems {
            archiveCompletedItem(item)
        }

        items.removeAll { $0.isFullyCompleted() }
        persistItems()
        persistCompletedRecords()
        syncWidgetData()
    }

    private func archiveIfCompleted(itemID: MemoryItem.ID) {
        guard let item = items.first(where: { $0.id == itemID }), item.isFullyCompleted() else {
            return
        }

        notificationManager.removeNotifications(for: item)
        archiveCompletedItem(item)
        items.removeAll { $0.id == itemID }
        persistCompletedRecords()
    }

    private func archiveCompletedItem(_ item: MemoryItem) {
        completedRecords.insert(
            CompletedMemoryRecord(itemName: item.listName),
            at: 0
        )
    }

    private func syncWidgetData() {
        let widgetItems = items.map { item in
            WidgetSharedStore.Item(
                id: item.id,
                listName: item.listName,
                reviewRecords: item.reviewRecords.map {
                    WidgetSharedStore.ReviewRecord(
                        id: $0.id,
                        targetDate: $0.targetDate,
                        isCompleted: $0.isCompleted
                    )
                }
            )
        }

        WidgetSharedStore.saveItems(widgetItems)
        WidgetCenter.shared.reloadTimelines(ofKind: "TodayReviewWidget")
    }
}
