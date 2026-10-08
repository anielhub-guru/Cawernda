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

    var onDismiss: (() -> Void)?
    var onOpenCawernda: (() -> Void)?
    var isVisible: Bool { !panels.isEmpty }

    func show(tasks: [ReminderTask], now: Date) {
        guard !tasks.isEmpty else { return }
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
                tasks: tasks,
                now: now,
                onDismiss: { [weak self] in self?.dismiss() },
                onOpenCawernda: { [weak self] in
                    self?.dismiss()
                    self?.onOpenCawernda?()
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
