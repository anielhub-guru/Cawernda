import XCTest
@testable import Cawernda

final class ReminderReviewPolicyTests: XCTestCase {
    func testReviewIsDueAfterConfiguredInterval() {
        let now = Date(timeIntervalSince1970: 20_000)
        XCTAssertTrue(ReminderReviewPolicy.shouldPresent(
            activeReminderCount: 2,
            intervalHours: 3,
            lastPresentedAt: now.addingTimeInterval(-(3 * 3600)),
            now: now,
            isOverlayVisible: false,
            isBusy: false
        ))
    }

    func testReviewIsSuppressedBeforeInterval() {
        let now = Date(timeIntervalSince1970: 20_000)
        XCTAssertFalse(ReminderReviewPolicy.shouldPresent(
            activeReminderCount: 2,
            intervalHours: 3,
            lastPresentedAt: now.addingTimeInterval(-3600),
            now: now,
            isOverlayVisible: false,
            isBusy: false
        ))
    }

    func testReviewRequiresActiveRemindersAndIdleUI() {
        let now = Date(timeIntervalSince1970: 20_000)
        XCTAssertFalse(ReminderReviewPolicy.shouldPresent(
            activeReminderCount: 0,
            intervalHours: 3,
            lastPresentedAt: nil,
            now: now,
            isOverlayVisible: false,
            isBusy: false
        ))
        XCTAssertFalse(ReminderReviewPolicy.shouldPresent(
            activeReminderCount: 1,
            intervalHours: 3,
            lastPresentedAt: nil,
            now: now,
            isOverlayVisible: false,
            isBusy: true
        ))
    }

    func testOffDisablesEvenForcedReview() {
        XCTAssertFalse(ReminderReviewPolicy.shouldPresent(
            activeReminderCount: 1,
            intervalHours: 0,
            lastPresentedAt: nil,
            now: Date(),
            isOverlayVisible: false,
            isBusy: false,
            force: true
        ))
    }
}
