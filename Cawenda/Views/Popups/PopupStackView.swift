import SwiftUI

public struct PopupStackView: View {
    public let title: String
    public let repeatIntervalHours: Int?
    public let firedAt: Date = Date()
    public let onDone: () -> Void
    public let onSnooze: (Int) -> Void
    public let onStillRunning: () -> Void
    public let onToggleChecklistItem: (UUID) -> Void
    @State private var isDismissing = false
    @State private var checklist: [ChecklistItem]
    @State private var isCompletedSectionExpanded = false

    public init(
        title: String,
        repeatIntervalHours: Int? = nil,
        checklist: [ChecklistItem] = [],
        onDone: @escaping () -> Void,
        onSnooze: @escaping (Int) -> Void,
        onStillRunning: @escaping () -> Void,
        onToggleChecklistItem: @escaping (UUID) -> Void = { _ in }
    ) {
        self.title = title
        self.repeatIntervalHours = repeatIntervalHours
        self.onDone = onDone
        self.onSnooze = onSnooze
        self.onStillRunning = onStillRunning
        self.onToggleChecklistItem = onToggleChecklistItem
        _checklist = State(initialValue: checklist)
    }

    private var checklistPresentation: PopupChecklistPresentation {
        PopupChecklistPresentation(items: checklist)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                // Title + timestamp
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color(nsColor: .labelColor))
                        .lineLimit(2)

                    HStack(spacing: 7) {
                        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                            Text(timeAgoString(from: firedAt, to: context.date))
                                .font(.footnote)
                                .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
                        }

                        RecurrenceIndicator(
                            repeatIntervalHours: repeatIntervalHours,
                            foregroundColor: Color(nsColor: .tertiaryLabelColor)
                        )
                    }
                }

                if !checklist.isEmpty {
                    checklistSection
                }

                // Primary actions
                HStack(spacing: 8) {
                    Button {
                        dismissWithAnimation(onDone)
                    } label: {
                        Label("Done", systemImage: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(PopupPrimaryActionButtonStyle())

                    Button {
                        dismissWithAnimation(onStillRunning)
                    } label: {
                        Text("Still Running (10m)")
                    }
                    .buttonStyle(PopupSecondaryActionButtonStyle())
                }
                .disabled(isDismissing)

                // Snooze row — always visible
                HStack(spacing: 7) {
                    ForEach([2, 5, 15, 60], id: \.self) { mins in
                        SnoozeChip(label: mins < 60 ? "\(mins)m" : "1h") {
                            dismissWithAnimation { onSnooze(mins) }
                        }
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .frame(
            width: PopupLayout.cardWidth,
            height: PopupLayout.cardHeight(hasChecklist: !checklist.isEmpty),
            alignment: .topLeading
        )
        .background(Color.clear)
        .scaleEffect(isDismissing ? 0.96 : 1.0)
        .offset(y: isDismissing ? 6 : 0)
        .opacity(isDismissing ? 0 : 1)
        .animation(.easeIn(duration: 0.25), value: isDismissing)
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text("Subtasks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(nsColor: .secondaryLabelColor))

                Spacer()

                Text("\(checklistPresentation.completedCount) of \(checklist.count) completed")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
            }

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 9) {
                    if checklistPresentation.remainingItems.isEmpty {
                        Label("All subtasks complete", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(nsColor: .systemGreen))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 5)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 7) {
                            ForEach(checklistPresentation.remainingItems) { item in
                                checklistButton(for: item)
                            }
                        }
                    }

                    if !checklistPresentation.completedItems.isEmpty {
                        DisclosureGroup(isExpanded: $isCompletedSectionExpanded) {
                            VStack(alignment: .leading, spacing: 7) {
                                ForEach(checklistPresentation.completedItems) { item in
                                    checklistButton(for: item)
                                }
                            }
                            .padding(.top, 7)
                        } label: {
                            Text("Completed (\(checklistPresentation.completedCount))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                        }
                        .tint(Color(nsColor: .tertiaryLabelColor))
                    }
                }
            }
            .frame(maxHeight: PopupLayout.checklistScrollMaxHeight)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.52))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
        }
    }

    private func checklistButton(for item: ChecklistItem) -> some View {
        Button {
            toggleChecklistItem(item.id)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(
                        item.isCompleted
                            ? Color(nsColor: .controlAccentColor)
                            : Color(nsColor: .secondaryLabelColor)
                    )

                Text(item.title)
                    .font(.caption)
                    .foregroundStyle(
                        item.isCompleted
                            ? Color(nsColor: .secondaryLabelColor)
                            : Color(nsColor: .labelColor)
                    )
                    .strikethrough(item.isCompleted)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityValue(item.isCompleted ? "Completed" : "Not completed")
        .accessibilityHint(item.isCompleted ? "Unchecks this subtask" : "Checks this subtask")
    }

    private func toggleChecklistItem(_ itemID: UUID) {
        guard let index = checklist.firstIndex(where: { $0.id == itemID }) else { return }

        withAnimation(.easeInOut(duration: 0.16)) {
            checklist[index].isCompleted.toggle()
        }
        onToggleChecklistItem(itemID)
    }

    private func timeAgoString(from date: Date, to now: Date) -> String {
        let diff = Int(now.timeIntervalSince(date))
        if diff < 60 { return "Fired just now" }
        let mins = diff / 60
        if mins < 60 { return "Fired \(mins)m ago" }
        return "Fired \(mins / 60)h \(mins % 60)m ago"
    }

    private func dismissWithAnimation(_ action: @escaping () -> Void) {
        guard !isDismissing else { return }

        withAnimation(.easeIn(duration: 0.25)) {
            isDismissing = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            action()
        }
    }
}

struct PopupChecklistPresentation {
    let remainingItems: [ChecklistItem]
    let completedItems: [ChecklistItem]

    init(items: [ChecklistItem]) {
        remainingItems = items.filter { !$0.isCompleted }
        completedItems = items.filter(\.isCompleted)
    }

    var completedCount: Int {
        completedItems.count
    }
}

enum PopupLayout {
    static let cardWidth: CGFloat = 380
    static let compactCardHeight: CGFloat = 180
    static let checklistCardHeight: CGFloat = 360
    static let checklistScrollMaxHeight: CGFloat = 142
    static let stackGap: CGFloat = 10
    static let moreIndicatorHeight: CGFloat = 40
    static let reservedVerticalSpace: CGFloat = 100
    static let maxVisibleCards = 3

    static func cardHeight(hasChecklist: Bool) -> CGFloat {
        hasChecklist ? checklistCardHeight : compactCardHeight
    }

    static func stackHeight(for tasks: [ReminderTask]) -> CGFloat {
        guard !tasks.isEmpty else { return 0 }

        let cardsHeight = tasks.reduce(CGFloat.zero) { total, task in
            total + cardHeight(hasChecklist: !task.checklist.isEmpty)
        }
        return cardsHeight + CGFloat(tasks.count - 1) * stackGap
    }

    static func canAdd(_ task: ReminderTask, to visibleTasks: [ReminderTask], screenHeight: CGFloat) -> Bool {
        guard visibleTasks.count < maxVisibleCards else { return false }
        guard !visibleTasks.isEmpty else { return true }

        return stackHeight(for: visibleTasks + [task]) <= max(0, screenHeight - reservedVerticalSpace)
    }
}

private struct SnoozeChipStyle: ButtonStyle {
    let isHovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .foregroundStyle(
                isHovering
                    ? Color(nsColor: .systemOrange)
                    : Color(nsColor: .tertiaryLabelColor)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        isHovering
                            ? Color(nsColor: .systemOrange).opacity(0.12)
                            : Color(nsColor: .quaternaryLabelColor).opacity(0.65)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovering ? 1.06 : 1.0))
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct PopupPrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PopupActionButton(configuration: configuration, hoverStyle: .done)
    }
}

private struct PopupSecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PopupActionButton(configuration: configuration, hoverStyle: .stillRunning)
    }
}

private enum PopupActionHoverStyle {
    case done
    case stillRunning
}

private struct PopupActionButton: View {
    let configuration: ButtonStyle.Configuration
    let hoverStyle: PopupActionHoverStyle
    @State private var isHovering = false

    private var backgroundColor: Color {
        guard isHovering else { return Color(nsColor: .controlColor) }

        switch hoverStyle {
        case .done:
            return Color(nsColor: .controlAccentColor)
        case .stillRunning:
            return Color(nsColor: .systemOrange).opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        guard isHovering else { return Color(nsColor: .labelColor) }

        switch hoverStyle {
        case .done:
            return .white
        case .stillRunning:
            return Color(nsColor: .systemOrange)
        }
    }

    var body: some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor)
            )
            .foregroundStyle(foregroundColor)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.12)) {
                    isHovering = hovering
                }
            }
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SnoozeChip: View {
    let label: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(label, action: action)
            .buttonStyle(SnoozeChipStyle(isHovering: isHovering))
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.12)) {
                    isHovering = hovering
                }
            }
    }
}

public struct MoreIndicatorView: View {
    public let count: Int
    public let onClick: () -> Void

    public init(count: Int, onClick: @escaping () -> Void) {
        self.count = count
        self.onClick = onClick
    }

    public var body: some View {
        Button(action: onClick) {
            Label("+\(count) more pending", systemImage: "tray.full.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(nsColor: .labelColor))
                .padding(12)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .frame(width: 380)
    }
}
