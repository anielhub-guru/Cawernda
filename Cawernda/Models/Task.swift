import Foundation

public struct ChecklistItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

public struct ReminderTask: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public let createdAt: Date
    public var reminderFiresAt: Date
    public var state: TaskState
    public var reminderFired: Bool
    public var reminderFiredAt: Date?

    // Lifecycle Intelligence
    public var originalDuration: TimeInterval
    public var snoozeCount: Int
    public var totalSnoozeDelay: TimeInterval
    public var completedAt: Date?
    public var checklist: [ChecklistItem]

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        reminderFiresAt: Date,
        state: TaskState = .active,
        reminderFired: Bool = false,
        reminderFiredAt: Date? = nil,
        originalDuration: TimeInterval? = nil,
        snoozeCount: Int = 0,
        totalSnoozeDelay: TimeInterval = 0,
        completedAt: Date? = nil,
        checklist: [ChecklistItem] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.reminderFiresAt = reminderFiresAt
        self.state = state
        self.reminderFired = reminderFired
        self.reminderFiredAt = reminderFiredAt

        self.originalDuration = originalDuration ?? reminderFiresAt.timeIntervalSince(createdAt)
        self.snoozeCount = snoozeCount
        self.totalSnoozeDelay = totalSnoozeDelay
        self.completedAt = completedAt
        self.checklist = checklist
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, createdAt, reminderFiresAt, state, reminderFired, reminderFiredAt
        case originalDuration, snoozeCount, totalSnoozeDelay, completedAt, checklist
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        reminderFiresAt = try container.decode(Date.self, forKey: .reminderFiresAt)
        state = try container.decode(TaskState.self, forKey: .state)
        reminderFired = try container.decode(Bool.self, forKey: .reminderFired)
        reminderFiredAt = try container.decodeIfPresent(Date.self, forKey: .reminderFiredAt)
        originalDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .originalDuration)
            ?? reminderFiresAt.timeIntervalSince(createdAt)
        snoozeCount = try container.decodeIfPresent(Int.self, forKey: .snoozeCount) ?? 0
        totalSnoozeDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .totalSnoozeDelay) ?? 0
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        checklist = try container.decodeIfPresent([ChecklistItem].self, forKey: .checklist) ?? []
    }
}
