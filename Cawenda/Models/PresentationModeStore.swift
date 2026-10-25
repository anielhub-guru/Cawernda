import Foundation
import Combine

enum PresentationModeIndicatorState: Equatable {
    case normal
    case active
    case waiting
}

@MainActor
public final class PresentationModeStore: ObservableObject {
    static let enabledDefaultsKey = "Cawenda.PresentationModeEnabled"

    @Published public private(set) var isEnabled: Bool
    @Published public private(set) var hasSuppressedReminders = false

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Self.enabledDefaultsKey)
    }

    var indicatorState: PresentationModeIndicatorState {
        guard isEnabled else { return .normal }
        return hasSuppressedReminders ? .waiting : .active
    }

    public func setEnabled(_ isEnabled: Bool) {
        self.isEnabled = isEnabled
        defaults.set(isEnabled, forKey: Self.enabledDefaultsKey)
        if !isEnabled {
            hasSuppressedReminders = false
        }
    }

    public func updateSuppressedReminders(_ hasSuppressedReminders: Bool) {
        self.hasSuppressedReminders = isEnabled && hasSuppressedReminders
    }
}
