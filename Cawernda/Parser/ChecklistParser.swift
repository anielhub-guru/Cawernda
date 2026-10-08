import Foundation

public struct ParsedChecklist: Equatable {
    public let title: String
    public let items: [ChecklistItem]
}

public struct ReminderDraft: Equatable {
    public let title: String
    public let checklist: [ChecklistItem]
    public let firesAt: Date
}

public enum ChecklistParser {
    public static func parse(_ input: String) -> ParsedChecklist? {
        let lines = input
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let first = lines.first else { return nil }

        let firstContent = content(from: first)
        let firstIsList = isListLine(first)
        let title = firstIsList ? firstContent : stripHeading(from: first)
        let itemLines = Array(lines.dropFirst())

        let items = itemLines.compactMap { line -> ChecklistItem? in
            let value = content(from: line)
            guard !value.isEmpty else { return nil }
            return ChecklistItem(title: value, isCompleted: isChecked(line))
        }

        guard !title.isEmpty else { return nil }
        return ParsedChecklist(title: title, items: items)
    }

    private static func stripHeading(from line: String) -> String {
        line.replacingOccurrences(
            of: #"^#{1,6}\s+"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func isListLine(_ line: String) -> Bool {
        line.range(of: #"^(?:[-*•]\s+|\d+[.)]\s+|\[[ xX]\]\s+)"#, options: .regularExpression) != nil
    }

    private static func isChecked(_ line: String) -> Bool {
        line.range(of: #"^(?:[-*•]\s+)?\[[xX]\]\s+"#, options: .regularExpression) != nil
    }

    private static func content(from line: String) -> String {
        line.replacingOccurrences(
            of: #"^(?:[-*•]\s+|\d+[.)]\s+)?(?:\[[ xX]\]\s+)?"#,
            with: "",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
