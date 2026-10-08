import XCTest
@testable import Cawernda

@MainActor
final class AlarmSoundManagerTests: XCTestCase {
    func testNoSoundIsTheDefault() {
        let suiteName = "AlarmSoundManagerTests.NoSound"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        XCTAssertNil(AlarmSoundManager.selectedFilename(defaults: defaults))
    }

    func testSelectedSoundFilenameIsPersisted() {
        let suiteName = "AlarmSoundManagerTests.SelectedSound"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("guitar-alarm.mp3", forKey: AlarmSoundManager.selectionKey)

        XCTAssertEqual(
            AlarmSoundManager.selectedFilename(defaults: defaults),
            "guitar-alarm.mp3"
        )
    }

    func testDisplayNameIsHumanReadable() {
        XCTAssertEqual(AlarmSoundManager.displayName(for: "choir-alarm2.mp3"), "Choir Alarm2")
    }
}
