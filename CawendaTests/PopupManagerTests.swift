import XCTest
@testable import Cawenda

@MainActor
final class PopupManagerTests: XCTestCase {

    private final class FakeAlarmSoundController: AlarmSoundControlling {
        var stopCallCount = 0
        func stop() { stopCallCount += 1 }
    }

    var store: TaskStore!
    var userDefaults: UserDefaults!
    var popupManager: PopupManager!
    private var soundController: FakeAlarmSoundController!

    let suiteName = "PopupManagerTestsSuite"
    var didOpenMenuBar = false

    override func setUp() async throws {
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        store = TaskStore(defaults: userDefaults)
        soundController = FakeAlarmSoundController()
        popupManager = PopupManager(taskStore: store, alarmSoundController: soundController)
        popupManager.onOpenMenuBar = { self.didOpenMenuBar = true }
        didOpenMenuBar = false
    }

    override func tearDown() async throws {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    func testSingleReminderFiresOneCardCreated() {
        let task = ReminderTask(title: "Task 1", reminderFiresAt: Date())
        popupManager.showPopup(for: task)

        XCTAssertEqual(popupManager.visiblePopups.count, 1)
        XCTAssertEqual(popupManager.overflowPopups.count, 0)
    }

    func testChecklistPresentationPrioritizesRemainingItems() {
        let remaining = ChecklistItem(title: "Call supplier")
        let completed = ChecklistItem(title: "Review stock", isCompleted: true)
        let presentation = PopupChecklistPresentation(items: [completed, remaining])

        XCTAssertEqual(presentation.remainingItems.map(\.id), [remaining.id])
        XCTAssertEqual(presentation.completedItems.map(\.id), [completed.id])
        XCTAssertEqual(presentation.completedCount, 1)
    }

    func testPlainReminderRetainsCompactPopupHeight() {
        XCTAssertEqual(PopupLayout.cardHeight(hasChecklist: false), 180)
    }

    func testChecklistReminderUsesExpandedPopupHeight() {
        XCTAssertGreaterThan(
            PopupLayout.cardHeight(hasChecklist: true),
            PopupLayout.cardHeight(hasChecklist: false)
        )
    }

    func testExpandedPopupsOverflowBeforeExceedingScreenHeight() {
        let checklist = [ChecklistItem(title: "First step")]
        let first = ReminderTask(title: "First", reminderFiresAt: Date(), checklist: checklist)
        let second = ReminderTask(title: "Second", reminderFiresAt: Date(), checklist: checklist)
        let third = ReminderTask(title: "Third", reminderFiresAt: Date(), checklist: checklist)

        XCTAssertTrue(PopupLayout.canAdd(first, to: [], screenHeight: 900))
        XCTAssertTrue(PopupLayout.canAdd(second, to: [first], screenHeight: 900))
        XCTAssertFalse(PopupLayout.canAdd(third, to: [first, second], screenHeight: 900))
    }

    func testThreeSimultaneousRemindersThreeCardsVisible() {
        popupManager.showPopup(for: ReminderTask(title: "1", reminderFiresAt: Date()))
        popupManager.showPopup(for: ReminderTask(title: "2", reminderFiresAt: Date()))
        popupManager.showPopup(for: ReminderTask(title: "3", reminderFiresAt: Date()))

        XCTAssertEqual(popupManager.visiblePopups.count, 3)
        XCTAssertEqual(popupManager.overflowPopups.count, 0)
    }

    func testFourthReminderShowsMoreIndicator() {
        popupManager.showPopup(for: ReminderTask(title: "1", reminderFiresAt: Date()))
        popupManager.showPopup(for: ReminderTask(title: "2", reminderFiresAt: Date()))
        popupManager.showPopup(for: ReminderTask(title: "3", reminderFiresAt: Date()))
        popupManager.showPopup(for: ReminderTask(title: "4", reminderFiresAt: Date()))

        XCTAssertEqual(popupManager.visiblePopups.count, 3)
        XCTAssertEqual(popupManager.overflowPopups.count, 1)
    }

    func testDismissingOneCardReflowsFromOverflow() {
        let t1 = ReminderTask(title: "1", reminderFiresAt: Date())
        let t2 = ReminderTask(title: "2", reminderFiresAt: Date())
        let t3 = ReminderTask(title: "3", reminderFiresAt: Date())
        let t4 = ReminderTask(title: "4", reminderFiresAt: Date())

        popupManager.showPopup(for: t1)
        popupManager.showPopup(for: t2)
        popupManager.showPopup(for: t3)
        popupManager.showPopup(for: t4)

        popupManager.dismissPopup(taskID: t1.id, withoutAction: false)

        XCTAssertEqual(popupManager.visiblePopups.count, 3)
        XCTAssertEqual(popupManager.overflowPopups.count, 0)
        XCTAssertEqual(popupManager.visiblePopups.last?.id, t4.id)
    }

    func testIndependentActionDoesNotAffectOthers() {
        let t1 = ReminderTask(title: "1", reminderFiresAt: Date())
        let t2 = ReminderTask(title: "2", reminderFiresAt: Date())
        let t3 = ReminderTask(title: "3", reminderFiresAt: Date())

        popupManager.showPopup(for: t1)
        popupManager.showPopup(for: t2)
        popupManager.showPopup(for: t3)

        popupManager.handleAction(.done, for: t2.id)

        XCTAssertEqual(popupManager.visiblePopups.count, 2)
        XCTAssertEqual(popupManager.visiblePopups[0].id, t1.id)
        XCTAssertEqual(popupManager.visiblePopups[1].id, t3.id)
    }

    func testClickingMoreOpensMenuBar() {
        popupManager.openMenuBar()
        XCTAssertTrue(didOpenMenuBar)
    }

    func testAllCardsDismissedLeavesEmptyStack() {
        let t1 = ReminderTask(title: "1", reminderFiresAt: Date())
        popupManager.showPopup(for: t1)
        popupManager.dismissPopup(taskID: t1.id, withoutAction: false)

        XCTAssertEqual(popupManager.visiblePopups.count, 0)
        XCTAssertEqual(popupManager.overflowPopups.count, 0)
    }

    func testSnoozeActionUpdatesTaskDismissesCard() {
        let task = ReminderTask(title: "1", reminderFiresAt: Date().addingTimeInterval(-100))
        store.add(task: task)
        popupManager.showPopup(for: task)

        let oldFiresAt = task.reminderFiresAt
        popupManager.handleAction(.snooze(5), for: task.id)

        XCTAssertEqual(popupManager.visiblePopups.count, 0)

        let updatedTask = store.tasks.first(where: { $0.id == task.id })!
        XCTAssertGreaterThan(updatedTask.reminderFiresAt, oldFiresAt)
        XCTAssertEqual(updatedTask.state, .stillRunning)
    }

    func testStillRunningActionUpdatesStateDismissesCard() {
        let task = ReminderTask(title: "1", reminderFiresAt: Date())
        store.add(task: task)
        popupManager.showPopup(for: task)

        popupManager.handleAction(.stillRunning, for: task.id)
        XCTAssertEqual(popupManager.visiblePopups.count, 0)
        XCTAssertEqual(store.tasks.first(where: { $0.id == task.id })?.state, .stillRunning)
    }

    func testDoneActionUpdatesStateDismissesCard() {
        let task = ReminderTask(title: "1", reminderFiresAt: Date())
        store.add(task: task)
        popupManager.showPopup(for: task)

        popupManager.handleAction(.done, for: task.id)
        XCTAssertEqual(popupManager.visiblePopups.count, 0)
        XCTAssertEqual(store.tasks.first(where: { $0.id == task.id })?.state, .done)
        XCTAssertEqual(soundController.stopCallCount, 1)
    }

    func testDismissWithoutActionMovesToPastDue() {
        let task = ReminderTask(title: "1", reminderFiresAt: Date())
        store.add(task: task)
        popupManager.showPopup(for: task)

        // Simulates closing window manually
        popupManager.dismissPopup(taskID: task.id, withoutAction: true)

        XCTAssertEqual(popupManager.visiblePopups.count, 0)
        XCTAssertEqual(store.tasks.first(where: { $0.id == task.id })?.state, .pastDue)
    }

    func testSnoozeWithCustomDuration() {
        let task = ReminderTask(title: "1", reminderFiresAt: store.now().addingTimeInterval(-100))
        store.add(task: task)
        popupManager.showPopup(for: task)

        let expectedNewFiresAt = store.now().addingTimeInterval(15 * 60)
        popupManager.handleAction(.snooze(15), for: task.id)

        XCTAssertEqual(popupManager.visiblePopups.count, 0)

        let updatedTask = store.tasks.first(where: { $0.id == task.id })!
        XCTAssertEqual(updatedTask.state, .stillRunning)
        XCTAssertEqual(updatedTask.reminderFiresAt.timeIntervalSince(expectedNewFiresAt), 0, accuracy: 0.1)
    }
}
