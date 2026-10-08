import SwiftUI

private enum ReminderDashboardMode: String, CaseIterable, Identifiable {
    case active = "Active"
    case history = "History"

    var id: Self { self }
}

public struct ReminderDashboardView: View {
    @Environment(\.openSettings) private var openSettings
    @ObservedObject var taskStore: TaskStore
    let onCompleteReminder: (UUID) -> Void
    @State private var mode: ReminderDashboardMode = .active
    @State private var taskToReuse: ReminderTask?
    @State private var reuseDate = Date()
    @State private var isConfirmingHistoryDeletion = false

    private var sections: [ReminderSection] {
        ReminderGrouping.sections(for: taskStore.activeTasks, now: taskStore.now())
    }

    public init(taskStore: TaskStore, onCompleteReminder: @escaping (UUID) -> Void = { _ in }) {
        self.taskStore = taskStore
        self.onCompleteReminder = onCompleteReminder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.vertical, 16)

            Divider()

            Picker("Reminder view", selection: $mode) {
                ForEach(ReminderDashboardMode.allCases) { viewMode in
                    Text(viewMode.rawValue).tag(viewMode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            Group {
                if mode == .active {
                    if sections.isEmpty {
                        activeEmptyState
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 18) {
                                ForEach(sections) { section in
                                    VStack(alignment: .leading, spacing: 8) {
                                        sectionHeader(section)

                                        ForEach(section.tasks) { task in
                                            ReminderListRow(
                                                task: task,
                                                store: taskStore,
                                                onComplete: onCompleteReminder
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                } else if taskStore.historyTasks.isEmpty {
                    historyEmptyState
                } else {
                    historyList
                }
            }
        }
        .frame(width: 420, height: 560, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $taskToReuse) { task in
            ReuseReminderSheet(task: task, firesAt: $reuseDate) {
                taskStore.reuse(id: task.id, newFiresAt: reuseDate)
                taskToReuse = nil
                mode = .active
            } onCancel: {
                taskToReuse = nil
            }
        }
        .alert("Delete reminder history?", isPresented: $isConfirmingHistoryDeletion) {
            Button("Cancel", role: .cancel) {}
            Button("Delete History", role: .destructive) {
                taskStore.deleteHistory()
            }
        } message: {
            Text("Completed and dismissed reminders will be permanently deleted. Active reminders will remain.")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSettingsWindow"))) { _ in
            openSettingsWindow()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Reminders")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(summary)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if mode == .history && !taskStore.historyTasks.isEmpty {
                Button {
                    isConfirmingHistoryDeletion = true
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("Delete history")
            }

            Button {
                openSettingsWindow()
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("Settings")

            Button {
                NotificationCenter.default.post(name: NSNotification.Name("ShowCommandWindow"), object: nil)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("New reminder")
        }
    }

    private var summary: String {
        if mode == .history {
            let count = taskStore.historyTasks.count
            return count == 1 ? "1 past reminder" : "\(count) past reminders"
        }
        let count = taskStore.activeTasks.count
        guard count > 0 else { return "Nothing is waiting on you" }
        return "\(count) active · grouped by what is coming next"
    }

    private func openSettingsWindow() {
        NotificationCenter.default.post(name: NSNotification.Name("ClosePopoverOnly"), object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
    }

    private func sectionHeader(_ section: ReminderSection) -> some View {
        HStack {
            Text(section.bucket.rawValue.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(section.bucket == .overdue ? Color.orange : Color.secondary)
            Spacer()
            Text("\(section.tasks.count)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 2)
    }

    private var activeEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Color.green)
            Text("All clear")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Add a reminder or paste a checklist.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
            Button("New reminder") {
                NotificationCenter.default.post(name: NSNotification.Name("ShowCommandWindow"), object: nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.secondary)
            Text("No reminder history")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Completed and dismissed reminders will appear here.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(taskStore.historyTasks) { task in
                    HistoryReminderRow(task: task, onReuse: {
                        reuseDate = taskStore.now().addingTimeInterval(600)
                        taskToReuse = task
                    }, onDelete: {
                        taskStore.delete(id: task.id)
                    })
                }
            }
            .padding(16)
        }
    }
}

private struct HistoryReminderRow: View {
    let task: ReminderTask
    let onReuse: () -> Void
    let onDelete: () -> Void
    @State private var isConfirmingDeletion = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: task.state == .done ? "checkmark.circle.fill" : "clock.badge.exclamationmark")
                    .foregroundStyle(task.state == .done ? Color.green : Color.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text(historyLabel)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Button("Reuse", action: onReuse)
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button {
                        isConfirmingDeletion = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Delete this reminder")
                }
            }

            if !task.checklist.isEmpty {
                Text("\(task.checklist.count) checklist item\(task.checklist.count == 1 ? "" : "s")")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 28)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Delete this reminder?", isPresented: $isConfirmingDeletion) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("\"\(task.title)\" will be permanently removed from History.")
        }
    }

    private var historyLabel: String {
        let status = task.state == .done ? "Completed" : "Dismissed"
        let date = task.completedAt ?? task.reminderFiredAt ?? task.reminderFiresAt
        return "\(status) · \(date.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct ReuseReminderSheet: View {
    let task: ReminderTask
    @Binding var firesAt: Date
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reuse reminder")
                    .font(.title2.weight(.semibold))
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            DatePicker(
                "Remind me",
                selection: $firesAt,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Create Reminder", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 390)
    }
}

private struct ReminderListRow: View {
    let task: ReminderTask
    @ObservedObject var store: TaskStore
    let onComplete: (UUID) -> Void
    @State private var isExpanded = true

    private var completedCount: Int {
        task.checklist.filter(\.isCompleted).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    store.markDone(id: task.id)
                    onComplete(task.id)
                } label: {
                    Image(systemName: "circle")
                        .font(.system(size: 17))
                        .foregroundStyle(task.state == .pastDue ? Color.orange : Color.secondary)
                }
                .buttonStyle(.plain)
                .help("Complete reminder")

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text(dueLabel)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(task.state == .pastDue ? Color.orange : Color.secondary)

                        if !task.checklist.isEmpty {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text("\(completedCount)/\(task.checklist.count)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer(minLength: 8)

                if !task.checklist.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                            .foregroundStyle(.tertiary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isExpanded && !task.checklist.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(task.checklist) { item in
                        Button {
                            store.toggleChecklistItem(taskID: task.id, itemID: item.id)
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(item.isCompleted ? Color.accentColor : Color.secondary)
                                Text(item.title)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                                    .strikethrough(item.isCompleted)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        }
        .contextMenu {
            Button("Snooze 10 minutes") {
                store.markStillRunning(id: task.id, newFiresAt: store.now().addingTimeInterval(600))
            }
            Button("Delete", role: .destructive) {
                store.delete(id: task.id)
            }
        }
    }

    private var dueLabel: String {
        if task.state == .pastDue || task.reminderFiresAt < store.now() {
            return "Overdue · \(task.reminderFiresAt.formatted(date: .abbreviated, time: .shortened))"
        }
        if Calendar.current.isDateInToday(task.reminderFiresAt) {
            return "Today at \(task.reminderFiresAt.formatted(date: .omitted, time: .shortened))"
        }
        return task.reminderFiresAt.formatted(date: .abbreviated, time: .shortened)
    }
}
