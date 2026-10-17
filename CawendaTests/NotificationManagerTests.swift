import XCTest
@testable import Cawenda

final class NotificationManagerTests: XCTestCase {
    func testReminderNotificationDoesNotAddASecondSound() {
        let task = ReminderTask(title: "Renew domain", reminderFiresAt: Date())
        let content = NotificationManager.reminderContent(for: task)

        XCTAssertEqual(content.title, "Reminder fired")
        XCTAssertEqual(content.body, task.title)
        XCTAssertNil(content.sound)
    }
}
