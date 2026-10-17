import AppKit
import SwiftUI

@MainActor
public class MenuBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var taskStore: TaskStore
    private var preferredContentHeight: CGFloat = 560

    public init(
        taskStore: TaskStore,
        onCompleteReminder: @escaping (UUID) -> Void
    ) {
        self.taskStore = taskStore
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = AlarmClockMenuIcon.make()
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 560)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ReminderDashboardView(
                taskStore: taskStore,
                onCompleteReminder: onCompleteReminder,
                onPreferredHeightChange: { [weak self] height in
                    self?.updatePopoverHeight(height)
                }
            )
        )

        statusItem.button?.target = self
    }

    @objc private func showCommandWindowFromMenu() {
        NotificationCenter.default.post(name: NSNotification.Name("ShowCommandWindow"), object: nil)
    }

    @objc private func openSettingsFromMenu() {
        NotificationCenter.default.post(name: NSNotification.Name("OpenSettingsWindow"), object: nil)
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            let menu = NSMenu()
            menu.addItem(withTitle: "New Reminder", action: #selector(showCommandWindowFromMenu), keyEquivalent: "n")
            menu.items.last?.target = self
            menu.addItem(withTitle: "Settings...", action: #selector(openSettingsFromMenu), keyEquivalent: ",")
            menu.items.last?.target = self
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Quit Cawenda", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
            return
        }

        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    public func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            updatePopoverHeight(preferredContentHeight)
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Force the popover's window to become key so it immediately accepts keyboard input
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    public func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }

    private func updatePopoverHeight(_ preferredHeight: CGFloat) {
        preferredContentHeight = preferredHeight
        let screenHeight = statusItem.button?.window?.screen?.visibleFrame.height
            ?? NSScreen.main?.visibleFrame.height
            ?? 720
        let maximumHeight = max(360, screenHeight - 24)
        popover.contentSize = NSSize(
            width: 420,
            height: min(max(360, preferredHeight), maximumHeight)
        )
    }
}
