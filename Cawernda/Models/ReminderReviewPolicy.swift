import Foundation

public enum ReminderReviewPolicy {
    public static func shouldPresent(
        activeReminderCount: Int,
        intervalHours: Int,
        lastPresentedAt: Date?,
        now: Date,
        isOverlayVisible: Bool,
        isBusy: Bool,
        force: Bool = false
    ) -> Bool {
        guard intervalHours > 0,
              activeReminderCount > 0,
              !isOverlayVisible,
              !isBusy else {
            return false
        }

        if force { return true }
        guard let lastPresentedAt else { return true }
        return now.timeIntervalSince(lastPresentedAt) >= TimeInterval(intervalHours * 3600)
    }
}
