import XCTest
@testable import Cawernda

final class DailyPlanningPromptPolicyTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testSameCalendarDayIsAlreadyHandled() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 8, hour: 17))!
        let earlier = calendar.date(from: DateComponents(year: 2026, month: 10, day: 8, hour: 8))!

        XCTAssertEqual(DailyPlanningPromptPolicy.decision(
            lastCheckedAt: earlier,
            now: now,
            activeReminderCount: 0,
            isBusy: false,
            calendar: calendar
        ), .alreadyHandled)
    }

    func testNewEmptyDayPresentsPrompt() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 8, hour: 8))!
        let yesterday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18))!

        XCTAssertEqual(DailyPlanningPromptPolicy.decision(
            lastCheckedAt: yesterday,
            now: now,
            activeReminderCount: 0,
            isBusy: false,
            calendar: calendar
        ), .present)
    }

    func testActiveRemindersHandleNewDayWithoutPrompt() {
        XCTAssertEqual(DailyPlanningPromptPolicy.decision(
            lastCheckedAt: nil,
            now: Date(),
            activeReminderCount: 1,
            isBusy: false,
            calendar: calendar
        ), .activeReminders)
    }

    func testBusyInterfaceDefersEmptyDay() {
        XCTAssertEqual(DailyPlanningPromptPolicy.decision(
            lastCheckedAt: nil,
            now: Date(),
            activeReminderCount: 0,
            isBusy: true,
            calendar: calendar
        ), .deferUntilIdle)
    }

    func testCalendarDayWinsOverElapsedTime() {
        let late = calendar.date(from: DateComponents(year: 2026, month: 10, day: 8, hour: 23, minute: 55))!
        let afterMidnight = calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 0, minute: 5))!

        XCTAssertEqual(DailyPlanningPromptPolicy.decision(
            lastCheckedAt: late,
            now: afterMidnight,
            activeReminderCount: 0,
            isBusy: false,
            calendar: calendar
        ), .present)
    }
}
