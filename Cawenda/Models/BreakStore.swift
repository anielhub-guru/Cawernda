import Foundation

public struct ActiveBreakSession: Equatable {
    public let startedAt: Date
    public let endsAt: Date
    public let prompt: BreakPrompt
}

public struct BreakStore {
    private let countKey = "Cawernda.BreaksTodayCount"
    private let dateKey = "Cawernda.BreaksTodayDate"
    private let skipCountKey = "Cawernda.BreakSkipsTodayCount"
    private let skipDateKey = "Cawernda.BreakSkipsTodayDate"
    private let activeBreakStartedAtKey = "Cawernda.ActiveBreakStartedAt"
    private let activeBreakEndsAtKey = "Cawernda.ActiveBreakEndsAt"
    private let activeBreakPromptKey = "Cawernda.ActiveBreakPrompt"
    private let legacyCountKey = "RemindMe.BreaksTodayCount"
    private let legacyDateKey = "RemindMe.BreaksTodayDate"
    private let defaults: UserDefaults
    private let now: () -> Date

    public init(
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.now = now

        if defaults.object(forKey: countKey) == nil,
           defaults.object(forKey: legacyCountKey) != nil {
            defaults.set(defaults.integer(forKey: legacyCountKey), forKey: countKey)
        }
        if defaults.object(forKey: dateKey) == nil,
           let legacyDate = defaults.string(forKey: legacyDateKey) {
            defaults.set(legacyDate, forKey: dateKey)
        }
    }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: now())
    }

    public var breaksToday: Int {
        countForToday(countKey: countKey, dateKey: dateKey)
    }

    public var skipsToday: Int {
        countForToday(countKey: skipCountKey, dateKey: skipDateKey)
    }

    public var activeBreakSession: ActiveBreakSession? {
        guard let startedAt = defaults.object(forKey: activeBreakStartedAtKey) as? Date,
              let endsAt = defaults.object(forKey: activeBreakEndsAtKey) as? Date,
              let prompt = BreakPrompt(rawValue: defaults.integer(forKey: activeBreakPromptKey)) else {
            return nil
        }

        return ActiveBreakSession(startedAt: startedAt, endsAt: endsAt, prompt: prompt)
    }

    public func remainingSkips(allowance: Int) -> Int {
        max(0, allowance - skipsToday)
    }

    @discardableResult
    public mutating func beginBreak(duration: TimeInterval, prompt: BreakPrompt) -> ActiveBreakSession {
        let startedAt = now()
        let session = ActiveBreakSession(
            startedAt: startedAt,
            endsAt: startedAt.addingTimeInterval(duration),
            prompt: prompt
        )
        defaults.set(session.startedAt, forKey: activeBreakStartedAtKey)
        defaults.set(session.endsAt, forKey: activeBreakEndsAtKey)
        defaults.set(session.prompt.rawValue, forKey: activeBreakPromptKey)
        return session
    }

    @discardableResult
    public mutating func completeActiveBreak() -> Bool {
        guard activeBreakSession != nil else { return false }
        clearActiveBreak()
        recordCompletedBreak()
        return true
    }

    @discardableResult
    public mutating func skipActiveBreak() -> Bool {
        guard activeBreakSession != nil else { return false }
        clearActiveBreak()
        recordSkip()
        return true
    }

    public mutating func clearActiveBreak() {
        defaults.removeObject(forKey: activeBreakStartedAtKey)
        defaults.removeObject(forKey: activeBreakEndsAtKey)
        defaults.removeObject(forKey: activeBreakPromptKey)
    }

    public mutating func recordCompletedBreak() {
        increment(countKey: countKey, dateKey: dateKey, currentCount: breaksToday)
    }

    public mutating func recordSkip() {
        increment(countKey: skipCountKey, dateKey: skipDateKey, currentCount: skipsToday)
    }

    private func countForToday(countKey: String, dateKey: String) -> Int {
        let storedDate = defaults.string(forKey: dateKey) ?? ""
        if storedDate == todayString {
            return defaults.integer(forKey: countKey)
        } else {
            return 0
        }
    }

    private mutating func increment(
        countKey: String,
        dateKey: String,
        currentCount: Int
    ) {
        defaults.set(currentCount + 1, forKey: countKey)
        defaults.set(todayString, forKey: dateKey)
    }
}

public enum BreakSkipSettings {
    public static let isEnabledKey = "enforceDailyBreakSkipLimit"
    public static let allowanceKey = "dailyBreakSkipAllowance"
    public static let defaultAllowance = 2

    public static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: isEnabledKey) as? Bool ?? true
    }

    public static func allowance(defaults: UserDefaults = .standard) -> Int {
        guard defaults.object(forKey: allowanceKey) != nil else {
            return defaultAllowance
        }
        return max(0, defaults.integer(forKey: allowanceKey))
    }
}
