import AppKit
import SwiftUI

public class LockOverlayPanel: NSPanel {
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }
}

@MainActor
public final class LockOverlayController: NSObject {
    private var panels: [LockOverlayPanel] = []
    private var localEventMonitor: Any?
    private var breakStore = BreakStore()
    private var wakeObservers: [NSObjectProtocol] = []

    public var onDismiss: (() -> Void)?
    public var isVisible: Bool { !panels.isEmpty }

    // Rotating break prompt index in-memory (not persisted)
    private static var promptIndex = 0

    public override init() {
        super.init()
        observeWakeEvents()

        Task { @MainActor [weak self] in
            self?.restoreActiveBreakIfNeeded()
        }
    }

    public func show(duration: TimeInterval) {
        closePanels()

        let prompts = BreakPrompt.allCases
        let prompt = prompts[Self.promptIndex]
        Self.promptIndex = (Self.promptIndex + 1) % prompts.count
        let session = breakStore.beginBreak(duration: duration, prompt: prompt)

        present(session: session)
    }

    public func restoreActiveBreakIfNeeded() {
        guard let session = breakStore.activeBreakSession else { return }

        if session.endsAt <= Date() {
            finishActiveBreak(outcome: .completed)
            return
        }

        closePanels()
        present(session: session)
    }

    private func present(session: ActiveBreakSession) {
        let prompt = session.prompt

        let breaksCount = breakStore.breaksToday
        let isSkipLimitEnabled = BreakSkipSettings.isEnabled()
        let skipAllowance = BreakSkipSettings.allowance()
        let skipsRemaining = isSkipLimitEnabled
            ? breakStore.remainingSkips(allowance: skipAllowance)
            : nil

        for screen in NSScreen.screens {
            let panel = LockOverlayPanel(
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

            let swiftUIView = LockOverlayView(
                startedAt: session.startedAt,
                endsAt: session.endsAt,
                prompt: prompt,
                breaksToday: breaksCount,
                skipsRemaining: skipsRemaining,
                onComplete: { [weak self] in
                    self?.dismiss(outcome: .completed)
                },
                onSkip: { [weak self] in
                    guard skipsRemaining == nil || (skipsRemaining ?? 0) > 0 else { return }
                    self?.dismiss(outcome: isSkipLimitEnabled ? .skipped : .neutral)
                }
            )

            let hostingView = NSHostingView(rootView: swiftUIView)
            panel.contentView = hostingView

            panel.alphaValue = 1.0
            panel.orderFrontRegardless()
            panels.append(panel)
        }

        // Key monitor: capture Escape (53) and Delete (51) while overlay is visible.
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let skipKey: BreakSkipKey?
            switch event.keyCode {
            case 53:
                skipKey = .escape
            case 51:
                skipKey = .delete
            default:
                skipKey = nil
            }

            if let skipKey {
                NotificationCenter.default.post(
                    name: NSNotification.Name("LockOverlaySkipKeyPressed"),
                    object: skipKey.rawValue
                )
                return nil
            }
            return event
        }

        // Activate app to ensure key events can be captured by our local monitor
        NSApp.activate(ignoringOtherApps: true)
    }

    public func dismiss() {
        dismiss(outcome: .neutral)
    }

    private enum DismissalOutcome {
        case completed
        case skipped
        case neutral
    }

    private func dismiss(outcome: DismissalOutcome) {
        guard breakStore.activeBreakSession != nil else { return }
        finishActiveBreak(outcome: outcome)
    }

    private func finishActiveBreak(outcome: DismissalOutcome) {
        let didFinish: Bool
        switch outcome {
        case .completed:
            didFinish = breakStore.completeActiveBreak()
        case .skipped:
            didFinish = breakStore.skipActiveBreak()
        case .neutral:
            breakStore.clearActiveBreak()
            didFinish = true
        }

        guard didFinish else { return }
        closePanels(notifyDismissal: true)
    }

    private func closePanels(notifyDismissal: Bool = false) {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }

        let currentPanels = panels
        panels.removeAll()

        guard !currentPanels.isEmpty else {
            if notifyDismissal {
                notifyOverlayDismissed()
            }
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            for panel in currentPanels {
                panel.animator().alphaValue = 0.0
            }
        }) {
            Task { @MainActor in
                for panel in currentPanels {
                    panel.orderOut(nil)
                }
                if notifyDismissal {
                    self.notifyOverlayDismissed()
                }
            }
        }
    }

    private func notifyOverlayDismissed() {
        onDismiss?()
        NotificationCenter.default.post(name: NSNotification.Name("LockOverlayDismissed"), object: nil)
    }

    private func observeWakeEvents() {
        let center = NSWorkspace.shared.notificationCenter
        let names: [Notification.Name] = [
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification
        ]

        wakeObservers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.restoreActiveBreakIfNeeded()
                }
            }
        }
    }
}
