import XCTest
@testable import Cawernda

final class TaskStoreTests: XCTestCase {

    var store: TaskStore!
    var userDefaults: UserDefaults!
    let suiteName = "TaskStoreTestsSuite"

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        store = TaskStore(defaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testAddTaskAppearsInActive() {
        let task = ReminderTask(title: "Test", reminderFiresAt: Date().addingTimeInterval(600))
        store.add(task: task)
        XCTAssertEqual(store.activeTasks.count, 1)
        XCTAssertEqual(store.activeTasks.first?.id, task.id)
    }

    func testMarkDoneTaskMovesOutOfActive() {
        let task = ReminderTask(title: "Test", reminderFiresAt: Date().addingTimeInterval(600))
        store.add(task: task)
        store.markDone(id: task.id)
        XCTAssertEqual(store.activeTasks.count, 0)
        XCTAssertEqual(store.tasks.first?.state, .done)
    }

    func testChecklistItemCanBeToggledAndPersists() throws {
        let child = ChecklistItem(title: "Verify deployment")
        let task = ReminderTask(
            title: "Release website",
            reminderFiresAt: Date().addingTimeInterval(600),
            checklist: [child]
        )
        store.add(task: task)

        store.toggleChecklistItem(taskID: task.id, itemID: child.id)

        let reloaded = TaskStore(defaults: userDefaults)
        XCTAssertTrue(try XCTUnwrap(reloaded.tasks.first?.checklist.first?.isCompleted))
    }

    func testLegacyTaskWithoutChecklistStillDecodes() throws {
        let task = ReminderTask(title: "Existing reminder", reminderFiresAt: Date())
        let encoded = try JSONEncoder().encode([task])
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [[String: Any]])
        json[0].removeValue(forKey: "checklist")
        userDefaults.set(try JSONSerialization.data(withJSONObject: json), forKey: "RemindMe.TaskStore.tasks")

        let reloaded = TaskStore(defaults: userDefaults)

        XCTAssertEqual(reloaded.tasks.first?.title, "Existing reminder")
        XCTAssertEqual(reloaded.tasks.first?.checklist, [])
    }

    func testMarkStillRunningStaysInActive() {
        let task = ReminderTask(title: "Test", reminderFiresAt: Date())
        store.add(task: task)
        store.markStillRunning(id: task.id, newFiresAt: Date().addingTimeInterval(300))
        XCTAssertEqual(store.activeTasks.count, 1)
        XCTAssertEqual(store.activeTasks.first?.state, .stillRunning)
    }

    func testDeleteTask() {
        let task = ReminderTask(title: "Test", reminderFiresAt: Date())
        store.add(task: task)
        XCTAssertEqual(store.tasks.count, 1)
        store.delete(id: task.id)
        XCTAssertEqual(store.tasks.count, 0)
    }

    func testCompletedTodayIncrements() {
        let task = ReminderTask(title: "Test", reminderFiresAt: Date())
        store.add(task: task)
        XCTAssertEqual(store.completedToday, 0)
        store.markDone(id: task.id)
        XCTAssertEqual(store.completedToday, 1)

        let task2 = ReminderTask(title: "Test 2", reminderFiresAt: Date())
        store.add(task: task2)
        store.markDone(id: task2.id)
        XCTAssertEqual(store.completedToday, 2)
    }

    func testCompletedTodayResetsAtMidnight() {
        var currentDate = Date()
        store = TaskStore(defaults: userDefaults, now: { currentDate })

        let task = ReminderTask(title: "Test", createdAt: currentDate, reminderFiresAt: currentDate)
        store.add(task: task)
        store.markDone(id: task.id)
        XCTAssertEqual(store.completedToday, 1)

        // Move to tomorrow
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        XCTAssertEqual(store.completedToday, 0)
    }

    func testPersistence() {
        let task = ReminderTask(title: "Persisted", reminderFiresAt: Date())
        store.add(task: task)

        let store2 = TaskStore(defaults: userDefaults)
        XCTAssertEqual(store2.tasks.count, 1)
        XCTAssertEqual(store2.tasks.first?.title, "Persisted")
    }

    func testActiveTasksExcludesDoneAndPastDue() {
        let t1 = ReminderTask(title: "A", reminderFiresAt: Date(), state: .active)
        let t2 = ReminderTask(title: "B", reminderFiresAt: Date(), state: .pastDue)
        let t3 = ReminderTask(title: "C", reminderFiresAt: Date(), state: .done)
        let t4 = ReminderTask(title: "D", reminderFiresAt: Date(), state: .stillRunning)

        store.add(task: t1)
        store.add(task: t2)
        store.add(task: t3)
        store.add(task: t4)

        XCTAssertEqual(store.activeTasks.count, 2)
        XCTAssertTrue(store.activeTasks.contains { $0.id == t1.id })
        XCTAssertTrue(store.activeTasks.contains { $0.id == t4.id })
    }

    func testPastDueTasksOnlyReturnsPastDue() {
        let t1 = ReminderTask(title: "A", reminderFiresAt: Date(), state: .active)
        let t2 = ReminderTask(title: "B", reminderFiresAt: Date(), state: .pastDue)

        store.add(task: t1)
        store.add(task: t2)

        XCTAssertEqual(store.pastDueTasks.count, 1)
        XCTAssertEqual(store.pastDueTasks.first?.id, t2.id)
    }

    func testHistoryContainsDoneAndPastDueOnly() {
        store.add(task: ReminderTask(title: "Active", reminderFiresAt: Date(), state: .active))
        store.add(task: ReminderTask(title: "Missed", reminderFiresAt: Date(), state: .pastDue))
        store.add(task: ReminderTask(title: "Done", reminderFiresAt: Date(), state: .done))

        XCTAssertEqual(Set(store.historyTasks.map(\.title)), Set(["Missed", "Done"]))
    }

    func testReuseCreatesFreshActiveCopyAndPreservesHistory() throws {
        let original = ReminderTask(
            title: "Renew domain",
            reminderFiresAt: Date(),
            state: .done,
            checklist: [ChecklistItem(title: "Confirm payment", isCompleted: true)]
        )
        store.add(task: original)
        let nextDate = Date().addingTimeInterval(3600)

        let reused = try XCTUnwrap(store.reuse(id: original.id, newFiresAt: nextDate))

        XCTAssertEqual(reused.state, .active)
        XCTAssertEqual(reused.reminderFiresAt, nextDate)
        XCTAssertFalse(try XCTUnwrap(reused.checklist.first).isCompleted)
        XCTAssertTrue(store.historyTasks.contains { $0.id == original.id })
    }

    func testDeleteHistoryPreservesActiveTasks() {
        store.add(task: ReminderTask(title: "Active", reminderFiresAt: Date(), state: .active))
        store.add(task: ReminderTask(title: "Missed", reminderFiresAt: Date(), state: .pastDue))
        store.add(task: ReminderTask(title: "Done", reminderFiresAt: Date(), state: .done))

        store.deleteHistory()

        XCTAssertEqual(store.tasks.map(\.title), ["Active"])
    }

    func testDeleteSingleHistoryReminderPreservesOtherTasks() {
        let active = ReminderTask(title: "Active", reminderFiresAt: Date(), state: .active)
        let firstHistory = ReminderTask(title: "First", reminderFiresAt: Date(), state: .done)
        let secondHistory = ReminderTask(title: "Second", reminderFiresAt: Date(), state: .pastDue)
        store.add(task: active)
        store.add(task: firstHistory)
        store.add(task: secondHistory)

        store.delete(id: firstHistory.id)

        XCTAssertEqual(Set(store.tasks.map(\.id)), Set([active.id, secondHistory.id]))
        XCTAssertEqual(store.historyTasks.map(\.id), [secondHistory.id])
    }

    func testMarkFiredSetsTimestamp() {
        let dateToInject = Date(timeIntervalSince1970: 1000)
        store = TaskStore(defaults: userDefaults, now: { dateToInject })
        let task = ReminderTask(title: "Test", reminderFiresAt: dateToInject.addingTimeInterval(600))
        store.add(task: task)

        store.markFired(id: task.id)

        let updatedTask = store.tasks.first(where: { $0.id == task.id })!
        XCTAssertTrue(updatedTask.reminderFired)
        XCTAssertEqual(updatedTask.reminderFiredAt, dateToInject)
    }
}
