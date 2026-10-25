import SwiftUI

private enum ReminderDashboardMode: String, CaseIterable, Identifiable {
    case active = "Active"
    case history = "History"

    var id: Self { self }
}

public struct ReminderDashboardView: View {
    @Environment(\.openSettings) private var openSettings
    @ObservedObject var taskStore: TaskStore
    @ObservedObject var presentationModeStore: PresentationModeStore
    let onSetPresentationMode: (Bool) -> Void
    let onCompleteReminder: (UUID) -> Void
    let onPreferredHeightChange: (CGFloat) -> Void
    @State private var mode: ReminderDashboardMode = .active
    @State private var taskToReuse: ReminderTask?
    @State private var taskToEdit: ReminderTask?
    @State private var reuseDate = Date()
    @State private var isConfirmingHistoryDeletion = false
    @State private var isReminderContentRevealed = false

    private var sections: [ReminderSection] {
        ReminderGrouping.sections(for: taskStore.activeTasks, now: taskStore.now())
    }

    public init(
        taskStore: TaskStore,
        presentationModeStore: PresentationModeStore,
        onSetPresentationMode: @escaping (Bool) -> Void = { _ in },
        onCompleteReminder: @escaping (UUID) -> Void = { _ in },
        onPreferredHeightChange: @escaping (CGFloat) -> Void = { _ in }
    ) {
        self.taskStore = taskStore
        self.presentationModeStore = presentationModeStore
        self.onSetPresentationMode = onSetPresentationMode
        self.onCompleteReminder = onCompleteReminder
        self.onPreferredHeightChange = onPreferredHeightChange
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.vertical, 16)

            Divider()

            if presentationModeStore.isEnabled && !isReminderContentRevealed {
                presentationModePrivacyView
            } else {
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
                                                    bucket: section.bucket,
                                                    store: taskStore,
                                                    onComplete: onCompleteReminder,
                                                    onEdit: { taskToEdit = task }
                                                )
                                            }

                                            Color.clear
                                                .frame(height: 6)
                                                .dropDestination(for: String.self) { values, _ in
                                                    guard let value = values.first,
                                                          let taskID = UUID(uuidString: value) else {
                                                        return false
                                                    }
                                                    taskStore.reorder(taskID: taskID, before: nil, in: section.bucket)
                                                    return true
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
        }
        .frame(width: 420)
        .frame(maxHeight: .infinity, alignment: .top)
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
        .sheet(item: $taskToEdit) { task in
            EditReminderSheet(task: task) { title, firesAt, checklist, repeatIntervalHours in
                taskStore.update(
                    id: task.id,
                    title: title,
                    reminderFiresAt: firesAt,
                    checklist: checklist,
                    repeatIntervalHours: repeatIntervalHours
                )
                taskToEdit = nil
            } onStopRepeating: {
                taskStore.stopRepeating(id: task.id)
                onCompleteReminder(task.id)
                taskToEdit = nil
            } onCancel: {
                taskToEdit = nil
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetDashboardPrivacy"))) { _ in
            isReminderContentRevealed = false
        }
        .onAppear {
            onPreferredHeightChange(preferredHeight)
        }
        .onChange(of: preferredHeight) { _, newHeight in
            onPreferredHeightChange(newHeight)
        }
        .onChange(of: presentationModeStore.isEnabled) { _, isEnabled in
            if !isEnabled { isReminderContentRevealed = false }
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

            if !presentationModeStore.isEnabled && mode == .history && !taskStore.historyTasks.isEmpty {
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
                let shouldEnable = !presentationModeStore.isEnabled
                isReminderContentRevealed = false
                onSetPresentationMode(shouldEnable)
            } label: {
                Image(systemName: "rectangle.on.rectangle")
                    .frame(width: 28, height: 28)
                    .background(presentationModeStore.isEnabled ? Color.blue : Color.clear)
                    .foregroundStyle(presentationModeStore.isEnabled ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(presentationModeStore.isEnabled ? "Turn off Presentation Mode" : "Turn on Presentation Mode")
            .accessibilityLabel(presentationModeStore.isEnabled ? "Presentation Mode on" : "Presentation Mode off")

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
        if presentationModeStore.isEnabled && !isReminderContentRevealed {
            return presentationModeStore.hasSuppressedReminders
                ? "Presentation Mode · reminder waiting"
                : "Presentation Mode · interruptions hidden"
        }
        if mode == .history {
            let count = taskStore.historyTasks.count
            return count == 1 ? "1 past reminder" : "\(count) past reminders"
        }
        let count = taskStore.activeTasks.count
        guard count > 0 else { return "Nothing is waiting on you" }
        return "\(count) active · grouped by what is coming next"
    }

    private var preferredHeight: CGFloat {
        if presentationModeStore.isEnabled && !isReminderContentRevealed {
            return 360
        }
        let chromeHeight: CGFloat = 142

        switch mode {
        case .active:
            guard !sections.isEmpty else { return 360 }
            let contentHeight = sections.reduce(CGFloat(32)) { total, section in
                let rowsHeight = section.tasks.reduce(CGFloat.zero) { rowTotal, task in
                    let checklistHeight = task.checklist.isEmpty ? 0 : CGFloat(task.checklist.count * 28 + 10)
                    return rowTotal + 72 + checklistHeight
                }
                return total + 30 + rowsHeight + CGFloat(max(0, section.tasks.count - 1) * 8) + 18
            }
            return max(360, chromeHeight + contentHeight)
        case .history:
            guard !taskStore.historyTasks.isEmpty else { return 360 }
            return max(360, chromeHeight + 32 + CGFloat(taskStore.historyTasks.count * 82))
        }
    }

    private var presentationModePrivacyView: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(presentationModeStore.hasSuppressedReminders ? Color.orange : Color.blue)
                    .frame(width: 58, height: 58)
                Image(systemName: presentationModeStore.hasSuppressedReminders ? "bell.badge.fill" : "rectangle.on.rectangle")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(presentationModeStore.hasSuppressedReminders ? "A reminder is waiting" : "Presentation Mode is on")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            Text("Reminder details and Cawenda interruptions stay hidden while you present.")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 290)

            if presentationModeStore.hasSuppressedReminders {
                Button("View Reminders") {
                    isReminderContentRevealed = true
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Turn Off Presentation Mode") {
                onSetPresentationMode(false)
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
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

private struct EditReminderSheet: View {
    let task: ReminderTask
    let onSave: (String, Date, [ChecklistItem], Int?) -> Void
    let onStopRepeating: () -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var firesAt: Date
    @State private var checklist: [ChecklistItem]
    @State private var repeatIntervalHours: Int?
    @State private var customRepeatHours: Int
    @State private var isChoosingCustomRepeat = false

    init(
        task: ReminderTask,
        onSave: @escaping (String, Date, [ChecklistItem], Int?) -> Void,
        onStopRepeating: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.task = task
        self.onSave = onSave
        self.onStopRepeating = onStopRepeating
        self.onCancel = onCancel
        _title = State(initialValue: task.title)
        _firesAt = State(initialValue: task.reminderFiresAt)
        _checklist = State(initialValue: task.checklist)
        _repeatIntervalHours = State(initialValue: task.repeatIntervalHours)
        _customRepeatHours = State(initialValue: task.repeatIntervalHours ?? 8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit reminder")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 7) {
                Text("Title")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Reminder title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            DatePicker(
                "Remind me",
                selection: $firesAt,
                displayedComponents: [.date, .hourAndMinute]
            )

            HStack {
                Text("Repeat")
                Spacer()
                recurrenceMenu
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        checklist.append(ChecklistItem(title: ""))
                    } label: {
                        Label("Add item", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach($checklist) { $item in
                            HStack(spacing: 8) {
                                Button {
                                    item.isCompleted.toggle()
                                } label: {
                                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(item.isCompleted ? Color.accentColor : Color.secondary)
                                }
                                .buttonStyle(.plain)

                                TextField("Checklist item", text: $item.title)
                                    .textFieldStyle(.roundedBorder)

                                Button {
                                    checklist.removeAll { $0.id == item.id }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .help("Remove checklist item")
                            }
                        }
                    }
                }
                .frame(minHeight: 80, maxHeight: 210)
            }

            HStack {
                if task.repeatIntervalHours != nil {
                    Button("Stop Repeating", role: .destructive, action: onStopRepeating)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save Changes", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 520, height: 430)
        .sheet(isPresented: $isChoosingCustomRepeat) {
            CustomEditRepeatIntervalSheet(hours: $customRepeatHours) {
                repeatIntervalHours = customRepeatHours
                isChoosingCustomRepeat = false
            } onCancel: {
                isChoosingCustomRepeat = false
            }
        }
    }

    private var recurrenceMenu: some View {
        Menu(repeatIntervalHours.map(repeatOptionLabel) ?? "Does not repeat") {
            Button("Does not repeat") {
                repeatIntervalHours = nil
            }
            Divider()
            ForEach([1, 2, 4, 6, 8, 12, 24], id: \.self) { hours in
                Button(repeatOptionLabel(hours)) {
                    repeatIntervalHours = hours
                }
            }
            Divider()
            Button("Custom…") {
                customRepeatHours = repeatIntervalHours ?? 8
                isChoosingCustomRepeat = true
            }
        }
        .fixedSize()
    }

    private func repeatOptionLabel(_ hours: Int) -> String {
        hours == 1 ? "Every hour" : "Every \(hours) hours"
    }

    private func save() {
        let normalizedChecklist = checklist.compactMap { item -> ChecklistItem? in
            let trimmedTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { return nil }
            return ChecklistItem(id: item.id, title: trimmedTitle, isCompleted: item.isCompleted)
        }
        onSave(
            title.trimmingCharacters(in: .whitespacesAndNewlines),
            firesAt,
            normalizedChecklist,
            repeatIntervalHours
        )
    }
}

private struct CustomEditRepeatIntervalSheet: View {
    @Binding var hours: Int
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Custom repeat interval")
                .font(.title3.weight(.semibold))
            Stepper(value: $hours, in: ReminderTask.allowedRepeatIntervalHours) {
                Text(hours == 1 ? "Every hour" : "Every \(hours) hours")
            }
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Apply", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 320)
    }
}

private struct ReminderListRow: View {
    let task: ReminderTask
    let bucket: ReminderBucket
    @ObservedObject var store: TaskStore
    let onComplete: (UUID) -> Void
    let onEdit: () -> Void
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

                        RecurrenceIndicator(repeatIntervalHours: task.repeatIntervalHours)

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
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(count: 2, perform: onEdit)
        .draggable(task.id.uuidString) {
            Text(task.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .dropDestination(for: String.self) { values, _ in
            guard let value = values.first,
                  let taskID = UUID(uuidString: value) else {
                return false
            }
            store.reorder(taskID: taskID, before: task.id, in: bucket)
            return true
        }
        .contextMenu {
            Button("Edit", action: onEdit)
            Button("Snooze 10 minutes") {
                store.markStillRunning(id: task.id, newFiresAt: store.now().addingTimeInterval(600))
            }
            if task.repeatIntervalHours != nil {
                Button("Stop Repeating") {
                    store.stopRepeating(id: task.id)
                    onComplete(task.id)
                }
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
