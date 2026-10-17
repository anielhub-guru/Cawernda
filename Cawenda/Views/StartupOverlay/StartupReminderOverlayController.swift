import AppKit
import SwiftUI

private final class StartupReminderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class StartupReminderOverlayController {
    private var panels: [StartupReminderPanel] = []
    private var localEventMonitor: Any?
    private var activeTasks: [ReminderTask] = []

    var onDismiss: (() -> Void)?
    var onOpenCawenda: (() -> Void)?
    var onAddReminder: (() -> Void)?
    var onCompleteReminder: ((UUID) -> Void)?
    var isVisible: Bool { !panels.isEmpty }

    func show(tasks: [ReminderTask], now: Date) {
        guard !tasks.isEmpty else { return }
        activeTasks = tasks
        present(mode: .activeReminders(tasks), now: now)
    }

    func showDailyPlanning(now: Date) {
        present(mode: .dailyPlanning, now: now)
    }

    private func present(mode: StartupReminderOverlayMode, now: Date) {
        dismiss(notify: false)

        for screen in NSScreen.screens {
            let panel = StartupReminderPanel(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.backgroundColor = .black
            panel.isOpaque = true
            panel.hasShadow = false
            panel.contentView = NSHostingView(rootView: StartupReminderOverlayView(
                mode: mode,
                now: now,
                onDismiss: { [weak self] in self?.dismiss() },
                onCompleteReminder: { [weak self] taskID in
                    self?.completeReminder(taskID)
                },
                onPrimaryAction: { [weak self] in
                    guard let self else { return }
                    self.dismiss()
                    switch mode {
                    case .activeReminders:
                        self.onOpenCawenda?()
                    case .dailyPlanning:
                        self.onAddReminder?()
                    }
                }
            ))
            panel.orderFrontRegardless()
            panels.append(panel)
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.dismiss()
                return nil
            }
            return event
        }
        NSApp.activate(ignoringOtherApps: true)
        panels.first?.makeKey()
    }

    private func completeReminder(_ taskID: UUID) {
        onCompleteReminder?(taskID)
        activeTasks.removeAll { $0.id == taskID }

        guard !activeTasks.isEmpty else {
            dismiss()
            return
        }
        present(mode: .activeReminders(activeTasks), now: Date())
    }

    func dismiss() {
        dismiss(notify: true)
    }

    private func dismiss(notify: Bool) {
        guard !panels.isEmpty else { return }
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        if notify { onDismiss?() }
    }
}
