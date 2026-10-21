import XCTest
@testable import Cawenda

final class RecurrenceIndicatorTests: XCTestCase {
    func testCompactLabelShowsHourlyInterval() {
        XCTAssertEqual(RecurrenceIndicatorText.compact(hours: 8), "Every 8h")
        XCTAssertEqual(RecurrenceIndicatorText.compact(hours: 1), "Every 1h")
    }

    func testAccessibilityLabelExpandsHourlyInterval() {
        XCTAssertEqual(RecurrenceIndicatorText.accessibilityLabel(hours: 8), "Repeats every 8 hours")
        XCTAssertEqual(RecurrenceIndicatorText.accessibilityLabel(hours: 1), "Repeats every 1 hour")
    }

    func testMissingOrInvalidIntervalOmitsIndicatorText() {
        XCTAssertNil(RecurrenceIndicatorText.compact(hours: nil))
        XCTAssertNil(RecurrenceIndicatorText.compact(hours: 0))
        XCTAssertNil(RecurrenceIndicatorText.compact(hours: 169))
    }
}
