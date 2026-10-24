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
    public static let defaultSoundFilename = "Morning String Rift.mp3"

    private var player: AVAudioPlayer?

    public static var availableSoundFilenames: [String] {
        resolvedSoundURLs().values
            .map(\.lastPathComponent)
            .sorted { displayName(for: $0) < displayName(for: $1) }
    }

    public static var userSoundsDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Cawenda", isDirectory: true)
            .appendingPathComponent("Sounds", isDirectory: true)
    }

    static var legacyUserSoundsDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Cawernda", isDirectory: true)
            .appendingPathComponent("Sounds", isDirectory: true)
    }

    @discardableResult
    public static func prepareUserSoundsDirectory() throws -> URL {
        guard let directory = userSoundsDirectory else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try prepareUserSoundsDirectory(
            at: directory,
            legacyDirectory: legacyUserSoundsDirectory
        )
    }

    @discardableResult
    static func prepareUserSoundsDirectory(
        at directory: URL,
        legacyDirectory: URL?,
        fileManager: FileManager = .default
    ) throws -> URL {
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        if let legacyDirectory,
           legacyDirectory.standardizedFileURL != directory.standardizedFileURL {
            for sourceURL in mp3URLs(in: legacyDirectory, fileManager: fileManager) {
                let destinationURL = directory.appendingPathComponent(sourceURL.lastPathComponent)
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                }
            }
        }

        return directory
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
        let filename = defaults.string(forKey: selectionKey) ?? defaultSoundFilename
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
        try? prepareUserSoundsDirectory()
    }

    private static func mp3URLs(
        in directory: URL?,
        fileManager: FileManager = .default
    ) -> [URL] {
        guard let directory else { return [] }
        return (try? fileManager.contentsOfDirectory(
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
