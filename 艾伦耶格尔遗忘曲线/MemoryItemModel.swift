import Foundation

struct MemoryItem: Codable, Identifiable, Equatable {
    var id: UUID
    var listName: String
    var creationDate: Date
    var groupID: UUID?
    var reviewRecords: [ReviewRecord]

    init(
        id: UUID = UUID(),
        listName: String,
        creationDate: Date,
        groupID: UUID? = nil,
        reviewRecords: [ReviewRecord]? = nil
    ) {
        self.id = id
        self.listName = listName
        self.creationDate = creationDate
        self.groupID = groupID
        self.reviewRecords = reviewRecords ?? ReviewSchedule.makeRecords(from: creationDate)
    }
}

struct MemoryGroup: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var colorName: GroupColorName
    var creationDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorName: GroupColorName,
        creationDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.creationDate = creationDate
    }
}

enum GroupColorName: String, Codable, CaseIterable, Identifiable {
    case red = "红色"
    case orange = "橙色"
    case yellow = "黄色"
    case green = "绿色"
    case blue = "蓝色"
    case purple = "紫色"
    case pink = "粉色"
    case gray = "灰色"

    var id: String { rawValue }
}

struct CompletedMemoryRecord: Codable, Identifiable, Equatable {
    var id: UUID
    var itemName: String
    var completionDate: Date

    init(id: UUID = UUID(), itemName: String, completionDate: Date = Date()) {
        self.id = id
        self.itemName = itemName
        self.completionDate = completionDate
    }
}

struct AppSettings: Codable, Equatable {
    var notificationsEnabled: Bool
    var notificationHour: Int
    var notificationMinute: Int

    static let `default` = AppSettings(
        notificationsEnabled: true,
        notificationHour: 9,
        notificationMinute: 0
    )

    var clampedHour: Int {
        min(max(notificationHour, 0), 23)
    }

    var clampedMinute: Int {
        min(max(notificationMinute, 0), 59)
    }
}

struct ReviewRecord: Codable, Identifiable, Equatable {
    var id: UUID
    var targetDate: Date
    var isCompleted: Bool

    init(id: UUID = UUID(), targetDate: Date, isCompleted: Bool = false) {
        self.id = id
        self.targetDate = targetDate
        self.isCompleted = isCompleted
    }
}

enum ReviewSchedule {
    static let intervals = [1, 2, 4, 7, 15, 30]

    static func makeRecords(from creationDate: Date, calendar: Calendar = .current) -> [ReviewRecord] {
        intervals.compactMap { dayOffset in
            guard let targetDate = targetDate(from: creationDate, dayOffset: dayOffset, calendar: calendar) else {
                return nil
            }
            return ReviewRecord(targetDate: targetDate)
        }
    }

    /// Calculates the target review date by treating the creation date as day 0,
    /// then normalizing the reminder time to 09:00 local time.
    static func targetDate(from creationDate: Date, dayOffset: Int, calendar: Calendar = .current) -> Date? {
        let startOfCreationDay = calendar.startOfDay(for: creationDate)
        guard let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: startOfCreationDay) else {
            return nil
        }

        return calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: targetDay
        )
    }

    static func dayOffset(for record: ReviewRecord, in item: MemoryItem, calendar: Calendar = .current) -> Int {
        let creationDay = calendar.startOfDay(for: item.creationDate)
        let targetDay = calendar.startOfDay(for: record.targetDate)
        return calendar.dateComponents([.day], from: creationDay, to: targetDay).day ?? 0
    }
}

enum ReviewRecordState {
    case overdue
    case today
    case upcoming
    case completed

    var title: String {
        switch self {
        case .overdue:
            return "已逾期"
        case .today, .upcoming:
            return "待复习"
        case .completed:
            return "已完成"
        }
    }
}

extension ReviewRecord {
    func state(relativeTo date: Date = Date(), calendar: Calendar = .current) -> ReviewRecordState {
        if isCompleted {
            return .completed
        }

        let comparison = calendar.compare(targetDate, to: date, toGranularity: .day)
        switch comparison {
        case .orderedAscending:
            return .overdue
        case .orderedSame:
            return .today
        case .orderedDescending:
            return .upcoming
        }
    }

    func isOverdue(relativeTo date: Date = Date(), calendar: Calendar = .current) -> Bool {
        !isCompleted && calendar.compare(targetDate, to: date, toGranularity: .day) == .orderedAscending
    }

    func isDueToday(relativeTo date: Date = Date(), calendar: Calendar = .current) -> Bool {
        !isCompleted && calendar.isDate(targetDate, inSameDayAs: date)
    }

    func isActionable(relativeTo date: Date = Date(), calendar: Calendar = .current) -> Bool {
        !isCompleted && calendar.compare(targetDate, to: date, toGranularity: .day) != .orderedDescending
    }
}

extension MemoryItem {
    func hasOverdueReviews(relativeTo date: Date = Date(), calendar: Calendar = .current) -> Bool {
        reviewRecords.contains { $0.isOverdue(relativeTo: date, calendar: calendar) }
    }

    func hasTodayReviews(relativeTo date: Date = Date(), calendar: Calendar = .current) -> Bool {
        reviewRecords.contains { $0.isDueToday(relativeTo: date, calendar: calendar) }
    }

    func overdueCount(relativeTo date: Date = Date(), calendar: Calendar = .current) -> Int {
        reviewRecords.filter { $0.isOverdue(relativeTo: date, calendar: calendar) }.count
    }

    func completedCount() -> Int {
        reviewRecords.filter(\.isCompleted).count
    }

    func isFullyCompleted() -> Bool {
        !reviewRecords.isEmpty && reviewRecords.allSatisfy(\.isCompleted)
    }
}
