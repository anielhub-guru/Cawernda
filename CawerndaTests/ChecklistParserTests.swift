import XCTest
@testable import Cawernda

final class ChecklistParserTests: XCTestCase {
    func testParsesHeadingAndMarkdownChecklist() throws {
        let input = """
        ### Job Applications

        - [ ] Review suggested job roles
        - [x] Identify suitable roles
        - Apply for selected roles
        """

        let result = try XCTUnwrap(ChecklistParser.parse(input))

        XCTAssertEqual(result.title, "Job Applications")
        XCTAssertEqual(result.items.map(\.title), [
            "Review suggested job roles",
            "Identify suitable roles",
            "Apply for selected roles"
        ])
        XCTAssertEqual(result.items.map(\.isCompleted), [false, true, false])
    }

    func testParsesNumberedAndBulletLines() throws {
        let result = try XCTUnwrap(ChecklistParser.parse("""
        Release website
        1. Renew certificate
        • Deploy backend
        * Verify health check
        """))

        XCTAssertEqual(result.title, "Release website")
        XCTAssertEqual(result.items.map(\.title), [
            "Renew certificate",
            "Deploy backend",
            "Verify health check"
        ])
    }

    func testSingleLineProducesSimpleReminder() throws {
        let result = try XCTUnwrap(ChecklistParser.parse("Follow up with client"))
        XCTAssertEqual(result.title, "Follow up with client")
        XCTAssertTrue(result.items.isEmpty)
    }
}
