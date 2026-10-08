import Foundation

public enum DailyPlanningPromptDecision: Equatable {
    case alreadyHandled
    case activeReminders
    case deferUntilIdle
    case present
}

public enum DailyPlanningPromptPolicy {
    public static func decision(
        lastCheckedAt: Date?,
        now: Date,
        activeReminderCount: Int,
        isBusy: Bool,
        calendar: Calendar = .current
    ) -> DailyPlanningPromptDecision {
        if let lastCheckedAt,
           calendar.isDate(lastCheckedAt, inSameDayAs: now) {
            return .alreadyHandled
        }
        if activeReminderCount > 0 {
            return .activeReminders
        }
        if isBusy {
            return .deferUntilIdle
        }
        return .present
    }
}
