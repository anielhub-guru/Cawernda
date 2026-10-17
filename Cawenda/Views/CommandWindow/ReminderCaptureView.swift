import SwiftUI

public struct ReminderCaptureView: View {
    @AppStorage("defaultReminderMinutes") private var defaultReminderMinutes = 10
    @ObservedObject private var state: CommandWindowState
    public var onCreate: (ReminderDraft) -> Void
    public var onCancel: () -> Void

    @State private var input = ""
    @State private var dueAt = Date().addingTimeInterval(600)
    @State private var hasChosenDate = false
    @FocusState private var isEditorFocused: Bool

    private var parsed: ParsedChecklist? {
        ChecklistParser.parse(input)
    }

    public init(
        state: CommandWindowState,
        onCreate: @escaping (ReminderDraft) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.state = state
        self.onCreate = onCreate
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("New reminder")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("Paste a title and checklist, or write a simple reminder.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("⌘↩ to save")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $input)
                    .font(.system(size: 15, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .focused($isEditorFocused)
                    .onKeyPress(keys: [.return], phases: .down) { press in
                        guard press.modifiers.contains(.command) else { return .ignored }
                        createReminder()
                        return .handled
                    }

                if input.isEmpty {
                    Text("Job Applications\n- Review suggested roles\n- Apply for selected roles")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 108)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }

            if let parsed, !parsed.items.isEmpty {
                Label(
                    "\(parsed.items.count) checklist item\(parsed.items.count == 1 ? "" : "s") detected",
                    systemImage: "checklist"
                )
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.accentColor)
            }

            HStack(spacing: 10) {
                DatePicker(
                    "Remind me",
                    selection: $dueAt,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .onChange(of: dueAt) { _, _ in hasChosenDate = true }

                quickDateButton("In 1 hour") {
                    dueAt = Date().addingTimeInterval(3600)
                }

                quickDateButton("Tomorrow") {
                    dueAt = Calendar.current.date(
                        bySettingHour: 9,
                        minute: 0,
                        second: 0,
                        of: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    ) ?? Date().addingTimeInterval(86_400)
                }

                Spacer()

                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                Button("Save", action: createReminder)
                    .buttonStyle(.borderedProminent)
                    .disabled(parsed == nil)
            }
        }
        .padding(20)
        .frame(width: 620, height: 300)
        .task(id: state.focusRequestID) {
            if input.isEmpty && !hasChosenDate {
                dueAt = defaultDueDate
            }
            await Task.yield()
            isEditorFocused = true
        }
    }

    private func quickDateButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label) {
            hasChosenDate = true
            action()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func createReminder() {
        guard var parsed else { return }
        var fireDate = dueAt

        if !hasChosenDate,
           case .success(let scheduled) = ReminderParser.parse(
               parsed.title,
               defaultDuration: TimeInterval(defaultReminderMinutes * 60)
           ) {
            parsed = ParsedChecklist(title: scheduled.title, items: parsed.items)
            fireDate = scheduled.firesAt
        }

        onCreate(ReminderDraft(title: parsed.title, checklist: parsed.items, firesAt: fireDate))
        input = ""
        dueAt = defaultDueDate
        hasChosenDate = false
        onCancel()
    }

    private var defaultDueDate: Date {
        Date().addingTimeInterval(TimeInterval(max(1, defaultReminderMinutes) * 60))
    }
}
