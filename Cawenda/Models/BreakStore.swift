import Foundation

public struct BreakStore {
    private let countKey = "Cawernda.BreaksTodayCount"
    private let dateKey = "Cawernda.BreaksTodayDate"
    private let legacyCountKey = "RemindMe.BreaksTodayCount"
    private let legacyDateKey = "RemindMe.BreaksTodayDate"

    public init() {
        let defaults = UserDefaults.standard
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
        return formatter.string(from: Date())
    }

    public var breaksToday: Int {
        let storedDate = UserDefaults.standard.string(forKey: dateKey) ?? ""
        if storedDate == todayString {
            return UserDefaults.standard.integer(forKey: countKey)
        } else {
            return 0
        }
    }

    public mutating func increment() {
        let currentCount = breaksToday
        UserDefaults.standard.set(currentCount + 1, forKey: countKey)
        UserDefaults.standard.set(todayString, forKey: dateKey)
    }
}
