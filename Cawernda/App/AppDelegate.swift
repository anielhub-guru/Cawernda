import AppKit
import ServiceManagement

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
    public var taskStore: TaskStore!
    public var menuBarController: MenuBarController!
    public var commandWindowController: CommandWindowController!
    public var popupManager: PopupManager!
    public var hotkeyManager: HotkeyManager!
    public var lockOverlayController: LockOverlayController!
    public var batteryManager: BatteryManager!
    public var breakManager: BreakManager!
    private var startupReminderOverlayController: StartupReminderOverlayController!

    private var taskTimer: Timer?
    private var reminderReviewTimer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var lastAlertedBatteryPercentage: Int?
    private var lastUsedNotificationStyle: Bool = false
    private var lastUsedThreshold: Int = 10
    private let lastReminderReviewDateKey = "Cawernda.LastReminderReviewDate"

    // Default to popup style unless user sets to true in settings
    private var useSystemNotifications: Bool {
        UserDefaults.standard.bool(forKey: "useSystemNotifications")
    }

    private var enableLowBatteryAlert: Bool {
        UserDefaults.standard.bool(forKey: "enableLowBatteryAlert")
    }

    private var lowBatteryThreshold: Int {
        let val = UserDefaults.standard.integer(forKey: "lowBatteryThreshold")
        return val == 0 ? 10 : val
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Match Buffer: set activation policy programmatically so the app
        // can properly activate and receive keyboard events in its windows.
        NSApp.setActivationPolicy(.accessory)

        taskStore = TaskStore()
        popupManager = PopupManager(taskStore: taskStore)
        menuBarController = MenuBarController(
            taskStore: taskStore,
            onCompleteReminder: { [weak popupManager] taskID in
                popupManager?.dismissPopup(taskID: taskID)
            }
        )
        commandWindowController = CommandWindowController()
        hotkeyManager = HotkeyManager()
        lockOverlayController = LockOverlayController()
        startupReminderOverlayController = StartupReminderOverlayController()
        breakManager = BreakManager(appDelegate: self)

        commandWindowController.onCreateReminder = { [weak self] draft in
            let task = ReminderTask(
                title: draft.title,
                reminderFiresAt: draft.firesAt,
                checklist: draft.checklist
            )
            self?.taskStore.add(task: task)
        }

        popupManager.onOpenMenuBar = { [weak self] in
            self?.menuBarController.showPopover(nil)
        }

        startupReminderOverlayController.onOpenCawernda = { [weak self] in
            self?.menuBarController.showPopover(nil)
        }

        // Wire up hotkey callback
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.commandWindowController.showWindow()
        }

        // Register the saved shortcut on launch.
        if let data = UserDefaults.standard.data(forKey: "globalShortcutData"),
           let shortcut = try? JSONDecoder().decode(Shortcut.self, from: data) {
            updateHotkey(shortcut: shortcut)
        } else {
            updateHotkey(shortcut: .defaultShortcut)
        }

        // Listen for hotkey changes from Settings
        NotificationCenter.default.addObserver(forName: .hotkeyChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                if let data = UserDefaults.standard.data(forKey: "globalShortcutData"),
                   let shortcut = try? JSONDecoder().decode(Shortcut.self, from: data) {
                    self?.updateHotkey(shortcut: shortcut)
                }
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowCommandWindow"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.menuBarController.closePopover(nil)
                self?.commandWindowController.showWindow()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("ClosePopoverOnly"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.menuBarController.closePopover(nil)
            }
        }

        // Temporarily unregister the hotkey while the ShortcutRecorder is capturing
        NotificationCenter.default.addObserver(forName: NSNotification.Name("HotkeyRecordingBegan"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.hotkeyManager.unregister()
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("HotkeyRecordingEnded"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.hotkeyManager.reregister()
            }
        }

        // Auto-register for launch at login on first run
        if !UserDefaults.standard.bool(forKey: "launchAtLoginPrompted") {
            UserDefaults.standard.set(true, forKey: "launchAtLoginPrompted")
            try? SMAppService.mainApp.register()
        }

        batteryManager = BatteryManager()
        setupBatteryMonitoring()
        if useSystemNotifications {
            NotificationManager.requestAuthorization()
        }

        startTaskTimer()
        startReminderReviewScheduling()
        showReminderReviewIfNeeded(force: true)

    }

    public func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
        batteryManager.stopMonitoring()
        taskTimer?.invalidate()
        reminderReviewTimer?.invalidate()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    public func updateHotkey(shortcut: Shortcut) {
        hotkeyManager.register(shortcut: shortcut)
        commandWindowController.updateShortcutHint(with: shortcut)
    }

    private func startTaskTimer() {
        taskTimer?.invalidate()
        taskTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkTasks()
            }
        }
    }

    private func checkTasks() {
        let now = taskStore.now()
        let firingTasks = taskStore.activeTasks.filter { $0.reminderFiresAt <= now && !$0.reminderFired }

        if !firingTasks.isEmpty {
            AlarmSoundManager.shared.playSelectedAlarm()
        }

        for task in firingTasks {
            if useSystemNotifications {
                NotificationManager.deliverSystemNotification(for: task)
                taskStore.markFired(id: task.id)
            } else {
                popupManager.showPopup(for: task)
            }
        }
    }

    private var reminderReviewIntervalHours: Int {
        let storedValue = UserDefaults.standard.object(forKey: "reminderReviewIntervalHours") as? Int
        return storedValue ?? 3
    }

    private func startReminderReviewScheduling() {
        reminderReviewTimer?.invalidate()
        reminderReviewTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.showReminderReviewIfNeeded()
            }
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.showReminderReviewIfNeeded()
            }
        }
    }

    private func showReminderReviewIfNeeded(force: Bool = false) {
        let now = taskStore.now()
        let isBusy = lockOverlayController.isVisible
            || popupManager.hasVisibleAlerts
            || commandWindowController.window?.isVisible == true
        let lastPresentedAt = UserDefaults.standard.object(forKey: lastReminderReviewDateKey) as? Date

        guard ReminderReviewPolicy.shouldPresent(
            activeReminderCount: taskStore.activeTasks.count,
            intervalHours: reminderReviewIntervalHours,
            lastPresentedAt: lastPresentedAt,
            now: now,
            isOverlayVisible: startupReminderOverlayController.isVisible,
            isBusy: isBusy,
            force: force
        ) else {
            return
        }

        let reminders = taskStore.activeTasks.sorted { $0.reminderFiresAt < $1.reminderFiresAt }
        startupReminderOverlayController.show(tasks: reminders, now: now)
        UserDefaults.standard.set(now, forKey: lastReminderReviewDateKey)
    }

    private func setupBatteryMonitoring() {
        lastUsedNotificationStyle = useSystemNotifications
        lastUsedThreshold = lowBatteryThreshold

        batteryManager.onBatteryStateChanged = { [weak self] state in
            self?.handleBatteryStateChange(state)
        }
        batteryManager.startMonitoring()
        evaluateBatteryState()

        // Listen for settings change via user defaults
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let currentStyle = self.useSystemNotifications
                let currentThreshold = self.lowBatteryThreshold
                if currentStyle != self.lastUsedNotificationStyle || currentThreshold != self.lastUsedThreshold {
                    self.lastUsedNotificationStyle = currentStyle
                    self.lastUsedThreshold = currentThreshold
                    self.lastAlertedBatteryPercentage = nil
                }
                self.evaluateBatteryState()
            }
        }
    }

    private func evaluateBatteryState() {
        guard let state = batteryManager.currentState else { return }
        handleBatteryStateChange(state)
    }

    private func handleBatteryStateChange(_ state: BatteryState) {
        guard enableLowBatteryAlert else {
            dismissBatteryAlerts()
            lastAlertedBatteryPercentage = nil
            return
        }

        if state.isConnectedToPower || state.isCharging {
            dismissBatteryAlerts()
            lastAlertedBatteryPercentage = nil
            return
        }

        if state.percentage < lowBatteryThreshold {
            let shouldAlert: Bool
            if let last = lastAlertedBatteryPercentage {
                shouldAlert = state.percentage < last
            } else {
                shouldAlert = true
            }

            if shouldAlert {
                lastAlertedBatteryPercentage = state.percentage
                let message = "Battery at \(state.percentage)% — plug in your charger."

                if useSystemNotifications {
                    NotificationManager.deliverLowBatteryNotification(message: message)
                    popupManager.dismissBatteryPopup()
                } else {
                    popupManager.showBatteryPopup(message: message)
                    NotificationManager.dismissLowBatteryNotification()
                }
            }
        } else {
            dismissBatteryAlerts()
            lastAlertedBatteryPercentage = nil
        }
    }

    private func dismissBatteryAlerts() {
        NotificationManager.dismissLowBatteryNotification()
        popupManager.dismissBatteryPopup()
    }
}
