import XCTest
@testable import Cawenda

final class ReminderGroupingTests: XCTestCase {
    func testGroupsOpenRemindersByUpcomingWindow() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 10, day: 8, hour: 12
        )))

        let tasks = [
            ReminderTask(title: "Overdue", reminderFiresAt: now.addingTimeInterval(-60)),
            ReminderTask(title: "Today", reminderFiresAt: now.addingTimeInterval(3600)),
            ReminderTask(title: "This week", reminderFiresAt: try XCTUnwrap(calendar.date(byAdding: .day, value: 3, to: now))),
            ReminderTask(title: "Later", reminderFiresAt: try XCTUnwrap(calendar.date(byAdding: .day, value: 10, to: now))),
            ReminderTask(title: "Done", reminderFiresAt: now, state: .done)
        ]

        let sections = ReminderGrouping.sections(for: tasks, now: now, calendar: calendar)

        XCTAssertEqual(sections.map(\.bucket), [.overdue, .today, .thisWeek, .later])
        XCTAssertEqual(sections.flatMap(\.tasks).map(\.title), ["Overdue", "Today", "This week", "Later"])
    }

    func testManualOrderTakesPriorityWithinAGroup() {
        let now = Date()
        let firstByDate = ReminderTask(
            title: "First by date",
            reminderFiresAt: now.addingTimeInterval(600),
            manualOrder: 1
        )
        let firstByPriority = ReminderTask(
            title: "First by priority",
            reminderFiresAt: now.addingTimeInterval(1_200),
            manualOrder: 0
        )

        let section = ReminderGrouping.sections(for: [firstByDate, firstByPriority], now: now).first

        XCTAssertEqual(section?.tasks.map(\.title), ["First by priority", "First by date"])
    }
}
