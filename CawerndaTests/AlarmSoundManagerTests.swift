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

    func testSoundResolutionAcceptsCaseInsensitiveMP3Extensions() {
        let sounds = AlarmSoundManager.resolvedSoundURLs(
            bundledURLs: [
                URL(fileURLWithPath: "/bundle/default-1.mp3"),
                URL(fileURLWithPath: "/bundle/default-2.MP3"),
                URL(fileURLWithPath: "/bundle/readme.txt")
            ],
            userURLs: []
        )

        XCTAssertEqual(Set(sounds.keys), ["default-1.mp3", "default-2.mp3"])
    }

    func testUserSoundOverridesBundledSoundWithSameFilename() {
        let bundled = URL(fileURLWithPath: "/bundle/custom.mp3")
        let user = URL(fileURLWithPath: "/user/Custom.MP3")

        let sounds = AlarmSoundManager.resolvedSoundURLs(
            bundledURLs: [bundled],
            userURLs: [user]
        )

        XCTAssertEqual(sounds["custom.mp3"], user)
    }

    func testUnavailableSelectionFallsBackToNoSound() {
        let suiteName = "AlarmSoundManagerTests.Unavailable"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("missing.mp3", forKey: AlarmSoundManager.selectionKey)

        XCTAssertNil(AlarmSoundManager.selectedFilename(
            defaults: defaults,
            availableFilenames: ["default-1.mp3"]
        ))
    }
}
