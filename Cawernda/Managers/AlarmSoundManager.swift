import AVFoundation
import Foundation

@MainActor
public protocol AlarmSoundControlling: AnyObject {
    func stop()
}

@MainActor
public final class AlarmSoundManager {
    public static let shared = AlarmSoundManager()
    public static let selectionKey = "Cawernda.AlarmSoundFilename"
    public static let noSoundValue = ""

    private var player: AVAudioPlayer?

    public static var availableSoundFilenames: [String] {
        resolvedSoundURLs().values
            .map(\.lastPathComponent)
            .sorted { displayName(for: $0) < displayName(for: $1) }
    }

    public static var userSoundsDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Cawernda", isDirectory: true)
            .appendingPathComponent("Sounds", isDirectory: true)
    }

    public static func displayName(for filename: String) -> String {
        URL(fileURLWithPath: filename)
            .deletingPathExtension()
            .lastPathComponent
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    public static func selectedFilename(
        defaults: UserDefaults = .standard,
        availableFilenames: [String]? = nil
    ) -> String? {
        let filename = defaults.string(forKey: selectionKey) ?? noSoundValue
        guard !filename.isEmpty else { return nil }
        guard let availableFilenames else { return filename }
        return availableFilenames.contains {
            $0.caseInsensitiveCompare(filename) == .orderedSame
        } ? filename : nil
    }

    public func playSelectedAlarm(defaults: UserDefaults = .standard) {
        guard let filename = Self.selectedFilename(
            defaults: defaults,
            availableFilenames: Self.availableSoundFilenames
        ) else {
            stop()
            return
        }
        play(filename: filename, playbackCount: 3)
    }

    public func preview(filename: String) {
        guard !filename.isEmpty else {
            stop()
            return
        }
        play(filename: filename, playbackCount: 1)
    }

    public func stop() {
        player?.stop()
        player = nil
    }

    private func play(filename: String, playbackCount: Int) {
        guard let url = Self.soundURL(for: filename),
              let soundPlayer = try? AVAudioPlayer(contentsOf: url) else {
            stop()
            return
        }

        stop()
        soundPlayer.numberOfLoops = max(0, playbackCount - 1)
        soundPlayer.prepareToPlay()
        soundPlayer.play()
        player = soundPlayer
    }

    static func soundURL(for filename: String) -> URL? {
        resolvedSoundURLs()[filename.lowercased()]
    }

    static func resolvedSoundURLs(
        bundledURLs: [URL]? = nil,
        userURLs: [URL]? = nil
    ) -> [String: URL] {
        let bundled = bundledURLs ?? mp3URLs(in: Bundle.main.resourceURL?
            .appendingPathComponent("sounds", isDirectory: true))
        let user = userURLs ?? mp3URLs(in: preparedUserSoundsDirectory())

        var resolved: [String: URL] = [:]
        for url in bundled where isMP3(url) {
            resolved[url.lastPathComponent.lowercased()] = url
        }
        for url in user where isMP3(url) {
            resolved[url.lastPathComponent.lowercased()] = url
        }
        return resolved
    }

    private static func preparedUserSoundsDirectory() -> URL? {
        guard let directory = userSoundsDirectory else { return nil }
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private static func mp3URLs(in directory: URL?) -> [URL] {
        guard let directory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ))?.filter(isMP3) ?? []
    }

    private static func isMP3(_ url: URL) -> Bool {
        url.pathExtension.caseInsensitiveCompare("mp3") == .orderedSame
    }
}

extension AlarmSoundManager: AlarmSoundControlling {}
