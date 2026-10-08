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
            .sorted { $0.reminderFiresAt < $1.reminderFiresAt }

        let grouped = Dictionary(grouping: visible) { task -> ReminderBucket in
            if task.reminderFiresAt < now || task.state == .pastDue { return .overdue }
            if calendar.isDate(task.reminderFiresAt, inSameDayAs: now) { return .today }
            let boundary = calendar.date(byAdding: .day, value: 7, to: now) ?? now
            return task.reminderFiresAt <= boundary ? .thisWeek : .later
        }

        return ReminderBucket.allCases.compactMap { bucket in
            guard let tasks = grouped[bucket], !tasks.isEmpty else { return nil }
            return ReminderSection(bucket: bucket, tasks: tasks)
        }
    }
}
