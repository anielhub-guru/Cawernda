import XCTest
@testable import Cawenda

@MainActor
final class PresentationModeStoreTests: XCTestCase {
    private let suiteName = "PresentationModeStoreTestsSuite"
    private var defaults: UserDefaults!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testEnabledStatePersistsAcrossStoreInstances() {
        let store = PresentationModeStore(defaults: defaults)
        store.setEnabled(true)

        XCTAssertTrue(PresentationModeStore(defaults: defaults).isEnabled)
    }

    func testIndicatorUsesNormalActiveAndWaitingStates() {
        let store = PresentationModeStore(defaults: defaults)
        XCTAssertEqual(store.indicatorState, .normal)

        store.setEnabled(true)
        XCTAssertEqual(store.indicatorState, .active)

        store.updateSuppressedReminders(true)
        XCTAssertEqual(store.indicatorState, .waiting)
    }

    func testDisablingClearsWaitingState() {
        let store = PresentationModeStore(defaults: defaults)
        store.setEnabled(true)
        store.updateSuppressedReminders(true)

        store.setEnabled(false)

        XCTAssertFalse(store.hasSuppressedReminders)
        XCTAssertEqual(store.indicatorState, .normal)
    }
}
