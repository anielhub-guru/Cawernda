import XCTest
@testable import Cawenda

@MainActor
final class LockTests: XCTestCase {

    var userDefaults: UserDefaults!
    let suiteName = "LockTestsSuite"
    let fixedDate = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() async throws {
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    func testBreakStoreIncrement() {
        var store = BreakStore(defaults: userDefaults, now: { self.fixedDate })

        XCTAssertEqual(store.breaksToday, 0)

        store.recordCompletedBreak()
        XCTAssertEqual(store.breaksToday, 1)

        store.recordCompletedBreak()
        XCTAssertEqual(store.breaksToday, 2)
    }

    func testBreakStoreResetsOnDifferentDate() {
        // Manually write an old date
        userDefaults.set(5, forKey: "Cawernda.BreaksTodayCount")
        userDefaults.set("2020-01-01", forKey: "Cawernda.BreaksTodayDate")

        var store = BreakStore(defaults: userDefaults, now: { self.fixedDate })
        XCTAssertEqual(store.breaksToday, 0) // Should reset to 0 since date is old

        store.recordCompletedBreak()
        XCTAssertEqual(store.breaksToday, 1) // Should start counting from 1 today
    }

    func testBreakStoreTracksSkipsSeparatelyAndClampsRemainingAllowance() {
        var store = BreakStore(defaults: userDefaults, now: { self.fixedDate })

        store.recordCompletedBreak()
        store.recordSkip()
        store.recordSkip()

        XCTAssertEqual(store.breaksToday, 1)
        XCTAssertEqual(store.skipsToday, 2)
        XCTAssertEqual(store.remainingSkips(allowance: 3), 1)
        XCTAssertEqual(store.remainingSkips(allowance: 1), 0)
    }

    func testActiveBreakPersistsWithAbsoluteDeadline() {
        var store = BreakStore(defaults: userDefaults, now: { self.fixedDate })
        let session = store.beginBreak(duration: 300, prompt: .standAndReach)

        XCTAssertEqual(session.startedAt, fixedDate)
        XCTAssertEqual(session.endsAt, fixedDate.addingTimeInterval(300))
        XCTAssertEqual(session.prompt, .standAndReach)

        let restoredStore = BreakStore(defaults: userDefaults, now: { self.fixedDate })
        XCTAssertEqual(restoredStore.activeBreakSession, session)
    }

    func testCompletingActiveBreakClearsSessionAndOnlyCountsOnce() {
        var store = BreakStore(defaults: userDefaults, now: { self.fixedDate })
        store.beginBreak(duration: 300, prompt: .standUp)

        XCTAssertTrue(store.completeActiveBreak())
        XCTAssertNil(store.activeBreakSession)
        XCTAssertEqual(store.breaksToday, 1)

        XCTAssertFalse(store.completeActiveBreak())
        XCTAssertEqual(store.breaksToday, 1)
    }

    func testSkippingActiveBreakClearsSessionAndOnlyCountsOnce() {
        var store = BreakStore(defaults: userDefaults, now: { self.fixedDate })
        store.beginBreak(duration: 300, prompt: .shortWalk)

        XCTAssertTrue(store.skipActiveBreak())
        XCTAssertNil(store.activeBreakSession)
        XCTAssertEqual(store.skipsToday, 1)

        XCTAssertFalse(store.skipActiveBreak())
        XCTAssertEqual(store.skipsToday, 1)
    }

    func testBreakSkipSettingsDefaultToEnabledWithTwoSkips() {
        XCTAssertTrue(BreakSkipSettings.isEnabled(defaults: userDefaults))
        XCTAssertEqual(
            BreakSkipSettings.allowance(defaults: userDefaults),
            BreakSkipSettings.defaultAllowance
        )
    }

    func testSameSkipKeyWithinTwoSecondsTriggersSkip() {
        var tracker = BreakSkipPressTracker()

        XCTAssertFalse(tracker.register(.escape, at: fixedDate))
        XCTAssertTrue(tracker.register(.escape, at: fixedDate.addingTimeInterval(1.9)))
        XCTAssertNil(tracker.armedKey)
    }

    func testMixedOrLateSkipKeyPressesDoNotTriggerSkip() {
        var tracker = BreakSkipPressTracker()

        XCTAssertFalse(tracker.register(.escape, at: fixedDate))
        XCTAssertFalse(tracker.register(.delete, at: fixedDate.addingTimeInterval(1)))
        XCTAssertFalse(tracker.register(.delete, at: fixedDate.addingTimeInterval(3.1)))
        XCTAssertEqual(tracker.armedKey, .delete)
    }
}
