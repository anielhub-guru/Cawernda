import SwiftUI
import AppKit
import ServiceManagement

// MARK: - ShortcutRecorder (matches Buffer's KeyRecorder pattern exactly)

/// Invisible NSViewRepresentable placed as .background() on the settings view.
/// When isRecording is true, updateNSView makes the view first responder to capture keys.
public struct ShortcutRecorder: NSViewRepresentable {
    @Binding public var isRecording: Bool
    public let onRecord: (Shortcut) -> Void

    public func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onRecord = onRecord
        return view
    }

    public func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.isRecording = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

public class ShortcutRecorderNSView: NSView {
    var isRecording = false
    var onRecord: ((Shortcut) -> Void)?

    public override var acceptsFirstResponder: Bool { true }

    // Match Buffer's KeyRecorderView.viewDidMoveToWindow — force activation
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            window.level = .floating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    public override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Ignore modifier-only presses (Shift=56, Control=59, Option=58, Command=55)
        if event.keyCode == 56 || event.keyCode == 59 || event.keyCode == 58 || event.keyCode == 55 {
            return
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.isEmpty || flags == .capsLock {
            NSSound.beep()
            return
        }

        let newShortcut = Shortcut(keyCode: event.keyCode, modifiers: flags.rawValue)
        onRecord?(newShortcut)
    }
}

// MARK: - SettingsView

public struct SettingsView: View {
    @AppStorage("defaultReminderMinutes") private var defaultMinutes = 10
    @AppStorage("useSystemNotifications") private var useSystemNotifications = false
    @AppStorage(AlarmSoundManager.selectionKey) private var alarmSoundFilename = AlarmSoundManager.noSoundValue
    @AppStorage("enableLowBatteryAlert") private var enableLowBatteryAlert = false
    @AppStorage("lowBatteryThreshold") private var lowBatteryThreshold = 10
    @AppStorage("reminderReviewIntervalHours") private var reminderReviewIntervalHours = 3

    @AppStorage("enablePeriodicBreaks") private var enablePeriodicBreaks = false
    @AppStorage("periodicBreakInterval") private var periodicBreakInterval = BreakReminderDefaults.intervalMinutes
    @AppStorage("periodicBreakDuration") private var periodicBreakDuration = BreakReminderDefaults.durationSeconds

    @Binding public var currentShortcut: Shortcut
    @State private var isRecording = false

    public init(shortcut: Binding<Shortcut>) {
        self._currentShortcut = shortcut
    }

    public var body: some View {
        VStack(spacing: 12) {
            Form {
                Section(header: Text("General")) {
                    GroupBox(label: Text("GENERAL").font(.caption2).foregroundStyle(.secondary)) {
                        VStack(alignment: .leading, spacing: 12) {

                            // MARK: Shortcut row
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 12) {
                                    Text("Global hotkey")

                                    Spacer()

                                    // Key badges
                                    HStack(spacing: 4) {
                                        let parts = currentShortcut.displayString.split(separator: " ")
                                        ForEach(0..<parts.count, id: \.self) { i in
                                            Text(String(parts[i]))
                                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(
                                                    isRecording
                                                        ? Color.accentColor.opacity(0.15)
                                                        : Color(NSColor.controlBackgroundColor)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(
                                                            isRecording ? Color.accentColor : Color.gray.opacity(0.3),
                                                            lineWidth: 1
                                                        )
                                                )
                                                .cornerRadius(6)
                                        }
                                    }

                                    Button(isRecording ? "Cancel" : "Change") {
                                        isRecording.toggle()
                                    }
                                    .buttonStyle(.bordered)
                                }

                                if isRecording {
                                    Text("Press your new shortcut…")
                                        .font(.caption)
                                        .foregroundStyle(Color.accentColor)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.15), value: isRecording)
                            .onChange(of: isRecording) { _, recording in
                                NotificationCenter.default.post(
                                    name: recording
                                        ? Notification.Name("HotkeyRecordingBegan")
                                        : Notification.Name("HotkeyRecordingEnded"),
                                    object: nil
                                )
                            }

                            Divider()

                            // MARK: Default duration
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Default reminder duration")
                                        .font(.body)
                                    Text("\(defaultMinutes) minutes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Stepper("", value: $defaultMinutes, in: 1...120)
                                    .labelsHidden()
                            }

                            Divider()

                            // MARK: Launch at Login
                            Toggle("Launch at Login", isOn: Binding(get: {
                                SMAppService.mainApp.status == .enabled
                            }, set: { newValue in
                                if newValue {
                                    try? SMAppService.mainApp.register()
                                } else {
                                    try? SMAppService.mainApp.unregister()
                                }
                            }))

                            Toggle("Use System Notifications", isOn: $useSystemNotifications)
                                .onChange(of: useSystemNotifications) { _, enabled in
                                    if enabled {
                                        NotificationManager.requestAuthorization()
                                    }
                                }

                            HStack {
                                Text("Reminder review")
                                Spacer()
                                Picker("Reminder review", selection: $reminderReviewIntervalHours) {
                                    Text("Off").tag(0)
                                    Text("Every 3h").tag(3)
                                    Text("Every 6h").tag(6)
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .frame(width: 220)
                            }

                            HStack {
                                Text("Alarm sound")

                                Spacer()

                                Picker("Alarm sound", selection: $alarmSoundFilename) {
                                    Text("No Sound").tag(AlarmSoundManager.noSoundValue)
                                    ForEach(AlarmSoundManager.availableSoundFilenames, id: \.self) { filename in
                                        Text(AlarmSoundManager.displayName(for: filename)).tag(filename)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 170)

                                Button("Preview") {
                                    AlarmSoundManager.shared.preview(filename: alarmSoundFilename)
                                }
                                .disabled(alarmSoundFilename.isEmpty)
                            }

                            Toggle("Low Battery Alert", isOn: $enableLowBatteryAlert.animation(.easeInOut(duration: 0.2)))

                            if enableLowBatteryAlert {
                                HStack {
                                    Text("Alert Threshold")
                                        .font(.body)
                                    Spacer()
                                    Picker("", selection: $lowBatteryThreshold) {
                                        Text("10%").tag(10)
                                        Text("15%").tag(15)
                                        Text("20%").tag(20)
                                        Text("30%").tag(30)
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                    .frame(width: 180)
                                }
                                .padding(.leading, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(8)
                    }
                }

                Section(header: Text("Periodic Breaks")) {
                    GroupBox(label: Text("EYE & FOCUS BREAKS").font(.caption2).foregroundStyle(.secondary)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Enable Periodic Break Reminders", isOn: $enablePeriodicBreaks.animation(.easeInOut(duration: 0.2)))

                            if enablePeriodicBreaks {
                                HStack {
                                    Text("Break Interval")
                                        .font(.body)
                                    Spacer()
                                    Picker("", selection: $periodicBreakInterval) {
                                        Text("20m").tag(20)
                                        Text("25m").tag(25)
                                        Text("30m").tag(30)
                                        Text("45m").tag(45)
                                        Text("60m").tag(60)
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                    .frame(width: 220)
                                }
                                .padding(.leading, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))

                                Divider()
                                    .padding(.leading, 16)

                                HStack {
                                    Text("Break Duration")
                                        .font(.body)
                                    Spacer()
                                    Picker("", selection: $periodicBreakDuration) {
                                        Text("20s").tag(20)
                                        Text("30s").tag(30)
                                        Text("1m").tag(60)
                                        Text("2m").tag(120)
                                        Text("5m").tag(300)
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                    .frame(width: 220)
                                }
                                .padding(.leading, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(8)
                    }
                }
            }

            Divider()
                .padding(.horizontal)

            VStack(spacing: 6) {
                Text("Designed to disappear. Built to remind.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
                    .italic()

                Text(appVersionLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.bottom, 12)
        }
        .padding()
        .frame(width: 520, height: 580)
        .background(
            ShortcutRecorder(isRecording: $isRecording) { newShortcut in
                currentShortcut = newShortcut
                isRecording = false
            }
        )
    }

    private var appVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Development"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return build.map { "Cawernda v\(version) (\($0))" } ?? "Cawernda v\(version)"
    }
}
