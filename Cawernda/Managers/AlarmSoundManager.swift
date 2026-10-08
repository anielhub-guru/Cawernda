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
        Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "sounds")?
            .map(\.lastPathComponent)
            .sorted { displayName(for: $0) < displayName(for: $1) } ?? []
    }

    public static func displayName(for filename: String) -> String {
        URL(fileURLWithPath: filename)
            .deletingPathExtension()
            .lastPathComponent
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    public static func selectedFilename(defaults: UserDefaults = .standard) -> String? {
        let filename = defaults.string(forKey: selectionKey) ?? noSoundValue
        return filename.isEmpty ? nil : filename
    }

    public func playSelectedAlarm(defaults: UserDefaults = .standard) {
        guard let filename = Self.selectedFilename(defaults: defaults) else {
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
        guard let url = Bundle.main.url(
            forResource: URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent,
            withExtension: URL(fileURLWithPath: filename).pathExtension,
            subdirectory: "sounds"
        ), let soundPlayer = try? AVAudioPlayer(contentsOf: url) else {
            stop()
            return
        }

        stop()
        soundPlayer.numberOfLoops = max(0, playbackCount - 1)
        soundPlayer.prepareToPlay()
        soundPlayer.play()
        player = soundPlayer
    }
}

extension AlarmSoundManager: AlarmSoundControlling {}
