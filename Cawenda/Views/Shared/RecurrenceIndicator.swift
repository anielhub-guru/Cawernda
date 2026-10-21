import SwiftUI

enum RecurrenceIndicatorText {
    static func compact(hours: Int?) -> String? {
        guard let hours, ReminderTask.allowedRepeatIntervalHours.contains(hours) else { return nil }
        return "Every \(hours)h"
    }

    static func accessibilityLabel(hours: Int?) -> String? {
        guard let hours, ReminderTask.allowedRepeatIntervalHours.contains(hours) else { return nil }
        return hours == 1 ? "Repeats every 1 hour" : "Repeats every \(hours) hours"
    }
}

struct RecurrenceIndicator: View {
    let repeatIntervalHours: Int?
    var foregroundColor: Color = .secondary

    @ViewBuilder
    var body: some View {
        if let compactText = RecurrenceIndicatorText.compact(hours: repeatIntervalHours),
           let accessibilityText = RecurrenceIndicatorText.accessibilityLabel(hours: repeatIntervalHours) {
            HStack(spacing: 3) {
                Image(systemName: "repeat")
                    .font(.system(size: 9, weight: .semibold))
                Text(compactText)
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(foregroundColor)
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
        }
    }
}
