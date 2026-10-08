import Foundation
import Combine

public class TaskStore: ObservableObject {
    @Published public private(set) var tasks: [ReminderTask] = []

    private let userDefaultsKey = "Cawernda.TaskStore.tasks"
    private let legacyUserDefaultsKey = "RemindMe.TaskStore.tasks"
    private let defaults: UserDefaults
    public var now: () -> Date

    public init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        migrateLegacyStorage()
        load()
        checkMissedRemindersOnLaunch()
    }

    public var activeTasks: [ReminderTask] {
        tasks.filter { $0.state == .active || $0.state == .stillRunning }
    }

    public var pastDueTasks: [ReminderTask] {
        tasks.filter { $0.state == .pastDue }
    }

    public var historyTasks: [ReminderTask] {
        tasks
            .filter { $0.state == .done || $0.state == .pastDue }
            .sorted {
                let leftDate = $0.completedAt ?? $0.reminderFiredAt ?? $0.reminderFiresAt
                let rightDate = $1.completedAt ?? $1.reminderFiredAt ?? $1.reminderFiresAt
                return leftDate > rightDate
            }
    }

    public var completedToday: Int {
        let currentDate = now()
        let calendar = Calendar.current
        return tasks.filter { task in
            task.state == .done
                && task.completedAt.map { calendar.isDate($0, inSameDayAs: currentDate) } == true
        }.count
    }

    public func add(task: ReminderTask) {
        tasks.append(task)
        save()
    }

    public func markDone(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].state = .done
            tasks[index].completedAt = now()
            save()
        }
    }

    public func toggleChecklistItem(taskID: UUID, itemID: UUID) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskID }),
              let itemIndex = tasks[taskIndex].checklist.firstIndex(where: { $0.id == itemID }) else {
            return
        }
        tasks[taskIndex].checklist[itemIndex].isCompleted.toggle()
        save()
    }

    public func markStillRunning(id: UUID, newFiresAt: Date) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            let oldFiresAt = tasks[index].reminderFiresAt
            let delayDiff = newFiresAt.timeIntervalSince(oldFiresAt)
            let addedDelay = max(0, delayDiff)

            tasks[index].state = .stillRunning
            tasks[index].reminderFiresAt = newFiresAt
            tasks[index].reminderFired = false
            tasks[index].reminderFiredAt = nil
            tasks[index].snoozeCount += 1
            tasks[index].totalSnoozeDelay += addedDelay
            save()
        }
    }

    public func delete(id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    public func reuse(id: UUID, newFiresAt: Date) -> ReminderTask? {
        guard let original = tasks.first(where: { $0.id == id }) else { return nil }

        let resetChecklist = original.checklist.map {
            ChecklistItem(title: $0.title)
        }
        let reusedTask = ReminderTask(
            title: original.title,
            createdAt: now(),
            reminderFiresAt: newFiresAt,
            checklist: resetChecklist
        )
        tasks.append(reusedTask)
        save()
        return reusedTask
    }

    // Function that changes active to pastDue when a popup is dismissed without action
    public func markPastDue(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].state = .pastDue
            save()
        }
    }

    // System calls this when popups are shown
    public func markFired(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].reminderFired = true
            tasks[index].reminderFiredAt = now()
            save()
        }
    }

    public func clearCompleted() {
        tasks.removeAll { $0.state == .done }
        save()
    }

    public func deleteHistory() {
        tasks.removeAll { $0.state == .done || $0.state == .pastDue }
        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            defaults.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func load() {
        if let data = defaults.data(forKey: userDefaultsKey) {
            do {
                let decoded = try JSONDecoder().decode([ReminderTask].self, from: data)
                self.tasks = decoded
            } catch {
                print("Unable to decode saved reminders. Original data has been preserved.")
                self.tasks = []
            }
        }
    }

    private func migrateLegacyStorage() {
        guard defaults.data(forKey: userDefaultsKey) == nil else { return }

        if let legacyData = defaults.data(forKey: legacyUserDefaultsKey) {
            defaults.set(legacyData, forKey: userDefaultsKey)
            return
        }

        guard defaults === UserDefaults.standard,
              let legacyDefaults = UserDefaults(suiteName: "com.local.RemindMeV1"),
              let legacyData = legacyDefaults.data(forKey: legacyUserDefaultsKey) else {
            return
        }
        defaults.set(legacyData, forKey: userDefaultsKey)
    }

    private func checkMissedRemindersOnLaunch() {
        // If a task fired, but wasn't marked done, check its state.
        // The popup manager will eventually hook in to schedule Notifications.
    }
}
