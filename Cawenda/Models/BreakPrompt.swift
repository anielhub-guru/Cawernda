import Foundation

enum BreakReminderDefaults {
    static let intervalMinutes = 60
    static let durationSeconds = 300
}

public enum BreakPrompt: Int, CaseIterable {
    case standUp
    case shortWalk
    case lookIntoDistance
    case blinkSlowly
    case relaxShoulders
    case stretchHandsAndWrists
    case standAndReach
    case breatheSlowly

    var instruction: String {
        switch self {
        case .standUp: "Stand up."
        case .shortWalk: "Take a short walk."
        case .lookIntoDistance: "Look into the distance."
        case .blinkSlowly: "Blink slowly several times."
        case .relaxShoulders: "Roll and relax your shoulders."
        case .stretchHandsAndWrists: "Stretch your hands and wrists."
        case .standAndReach: "Stand and reach overhead."
        case .breatheSlowly: "Breathe slowly."
        }
    }

    var guidance: String {
        switch self {
        case .standUp: "Leave the chair and straighten your legs."
        case .shortWalk: "Move away from the screen for a few minutes."
        case .lookIntoDistance: "Focus on something across the room or outside."
        case .blinkSlowly: "Let each blink close fully before opening your eyes."
        case .relaxShoulders: "Lift, roll back, and let your shoulders drop."
        case .stretchHandsAndWrists: "Open your hands, then gently circle your wrists."
        case .standAndReach: "Stand tall and extend both arms above your head."
        case .breatheSlowly: "Take an easy breath in, then a longer breath out."
        }
    }
}
