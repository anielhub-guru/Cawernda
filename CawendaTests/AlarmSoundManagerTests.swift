import XCTest
@testable import Cawenda

@MainActor
final class AlarmSoundManagerTests: XCTestCase {
    func testMorningStringRiftIsTheDefault() {
        let suiteName = "AlarmSoundManagerTests.NoSound"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        XCTAssertEqual(
            AlarmSoundManager.selectedFilename(defaults: defaults),
            "Morning String Rift.mp3"
        )
    }

    func testExplicitNoSoundSelectionIsPreserved() {
        let suiteName = "AlarmSoundManagerTests.ExplicitNoSound"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(AlarmSoundManager.noSoundValue, forKey: AlarmSoundManager.selectionKey)

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

    func testMissingBundledDefaultFallsBackToNoSound() {
        let suiteName = "AlarmSoundManagerTests.MissingDefault"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        XCTAssertNil(AlarmSoundManager.selectedFilename(
            defaults: defaults,
            availableFilenames: ["default-1.mp3"]
        ))
    }

    func testPreparingSoundsDirectoryCopiesLegacyMP3FilesWithoutOverwritingCurrentFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let legacy = root.appendingPathComponent("Cawernda/Sounds", isDirectory: true)
        let current = root.appendingPathComponent("Cawenda/Sounds", isDirectory: true)
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: current, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let legacyOnly = legacy.appendingPathComponent("legacy.mp3")
        let legacyDuplicate = legacy.appendingPathComponent("custom.mp3")
        let currentDuplicate = current.appendingPathComponent("custom.mp3")
        try Data("legacy".utf8).write(to: legacyOnly)
        try Data("old".utf8).write(to: legacyDuplicate)
        try Data("current".utf8).write(to: currentDuplicate)

        let prepared = try AlarmSoundManager.prepareUserSoundsDirectory(
            at: current,
            legacyDirectory: legacy
        )

        XCTAssertEqual(prepared, current)
        XCTAssertEqual(
            try Data(contentsOf: current.appendingPathComponent("legacy.mp3")),
            Data("legacy".utf8)
        )
        XCTAssertEqual(try Data(contentsOf: currentDuplicate), Data("current".utf8))
    }
}
