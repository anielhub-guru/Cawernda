import XCTest
@testable import Cawernda

final class BreakPromptTests: XCTestCase {
    func testPromptRotationContainsEightDistinctInstructions() {
        let prompts = BreakPrompt.allCases

        XCTAssertEqual(prompts.count, 8)
        XCTAssertEqual(Set(prompts.map(\.instruction)).count, prompts.count)
        XCTAssertEqual(prompts.first, .standUp)
        XCTAssertTrue(prompts.contains(.standAndReach))
    }

    func testRecommendedDefaults() {
        XCTAssertEqual(BreakReminderDefaults.intervalMinutes, 60)
        XCTAssertEqual(BreakReminderDefaults.durationSeconds, 300)
    }
}
