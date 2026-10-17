import Foundation

public enum ReminderBucket: String, CaseIterable {
    case overdue = "Overdue"
    case today = "Today"
    case thisWeek = "Next 7 Days"
    case later = "Later"
}

public struct ReminderSection: Identifiable, Equatable {
    public let bucket: ReminderBucket
    public let tasks: [ReminderTask]
    public var id: ReminderBucket { bucket }
}

public enum ReminderGrouping {
    public static func sections(
        for tasks: [ReminderTask],
        now: Date,
        calendar: Calendar = .current
    ) -> [ReminderSection] {
        let visible = tasks
            .filter { $0.state != .done }
            .sorted(by: precedes)

        let grouped = Dictionary(grouping: visible) { task -> ReminderBucket in
            bucket(for: task, now: now, calendar: calendar)
        }

        return ReminderBucket.allCases.compactMap { bucket in
            guard let tasks = grouped[bucket], !tasks.isEmpty else { return nil }
            return ReminderSection(bucket: bucket, tasks: tasks)
        }
    }

    public static func bucket(
        for task: ReminderTask,
        now: Date,
        calendar: Calendar = .current
    ) -> ReminderBucket {
        if task.reminderFiresAt < now || task.state == .pastDue { return .overdue }
        if calendar.isDate(task.reminderFiresAt, inSameDayAs: now) { return .today }
        let boundary = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        return task.reminderFiresAt <= boundary ? .thisWeek : .later
    }

    private static func precedes(_ left: ReminderTask, _ right: ReminderTask) -> Bool {
        switch (left.manualOrder, right.manualOrder) {
        case let (.some(leftOrder), .some(rightOrder)) where leftOrder != rightOrder:
            return leftOrder < rightOrder
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            if left.reminderFiresAt != right.reminderFiresAt {
                return left.reminderFiresAt < right.reminderFiresAt
            }
            return left.createdAt < right.createdAt
        }
    }
}
