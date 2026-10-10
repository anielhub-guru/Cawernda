import SwiftUI

enum StartupReminderOverlayMode {
    case activeReminders([ReminderTask])
    case dailyPlanning
}

struct StartupReminderOverlayView: View {
    let mode: StartupReminderOverlayMode
    let now: Date
    let onDismiss: () -> Void
    let onPrimaryAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Text(now.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                overlayContent

                actionButtons

                Text("Press Esc to dismiss")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(40)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch mode {
        case .activeReminders:
            HStack(spacing: 12) {
                dismissButton
                primaryButton
                dismissButton
                    .hidden()
                    .accessibilityHidden(true)
            }
        case .dailyPlanning:
            HStack(spacing: 12) {
                dismissButton
                primaryButton
                dismissButton
                    .hidden()
                    .accessibilityHidden(true)
            }
        }
    }

    private var dismissButton: some View {
        Button(dismissButtonTitle, action: onDismiss)
            .buttonStyle(.bordered)
            .controlSize(.large)
    }

    private var primaryButton: some View {
        Button(primaryButtonTitle, action: onPrimaryAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch mode {
        case .activeReminders(let tasks):
            VStack(spacing: 7) {
                Text("Still on your radar")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(tasks.count == 1 ? "1 active reminder" : "\(tasks.count) active reminders")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(tasks) { task in
                        reminderRow(task)
                    }
                }
            }
            .frame(maxWidth: 660, maxHeight: 330)

        case .dailyPlanning:
            VStack(spacing: 10) {
                Text("What do you want to do today?")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Add a reminder so it stays on your radar.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: 660, minHeight: 190)
        }
    }

    private func reminderRow(_ task: ReminderTask) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "circle")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(dueLabel(for: task))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(task.reminderFiresAt < now ? Color.orange : Color.white.opacity(0.45))
            }

            Spacer()

            if !task.checklist.isEmpty {
                Text("\(task.checklist.filter(\.isCompleted).count)/\(task.checklist.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dismissButtonTitle: String {
        switch mode {
        case .activeReminders: "Dismiss"
        case .dailyPlanning: "Not now"
        }
    }

    private var primaryButtonTitle: String {
        switch mode {
        case .activeReminders: "Open Cawernda"
        case .dailyPlanning: "Add a reminder"
        }
    }

    private func dueLabel(for task: ReminderTask) -> String {
        if task.reminderFiresAt < now {
            return "Overdue · \(task.reminderFiresAt.formatted(date: .abbreviated, time: .shortened))"
        }
        if Calendar.current.isDateInToday(task.reminderFiresAt) {
            return "Today at \(task.reminderFiresAt.formatted(date: .omitted, time: .shortened))"
        }
        return task.reminderFiresAt.formatted(date: .abbreviated, time: .shortened)
    }
}
