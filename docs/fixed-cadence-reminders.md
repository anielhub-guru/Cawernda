# Fixed-Cadence Reminders

## Understanding Summary

- Cawenda will support reminders that repeat every configurable number of hours.
- Repetition is anchored to the original scheduled time rather than the completion time.
- The repeat control appears immediately after the **Tomorrow** pill in the reminder capture window.
- **Done** completes the current occurrence and advances the reminder to its next scheduled occurrence.
- **Stop Repeating** ends the series and moves the reminder to History.
- Missed occurrences do not stack, shift the cadence, or trigger medication-specific advice.
- One-time reminders retain their existing behavior.

## Assumptions

- A missing repeat interval means the reminder does not repeat.
- Repeat intervals use whole hours from 1 through 168.
- The repeat menu provides common presets plus a custom-hours option.
- If several occurrences pass while Cawenda is unavailable, only one overdue occurrence is presented.
- Completing an overdue occurrence advances it to the first future time on the original cadence.
- Snoozing affects the current alert only and does not change the cadence anchor.
- Editing the scheduled date establishes a new cadence anchor.
- Checklist items reset when the next occurrence is scheduled.
- Existing saved reminders decode as non-repeating.
- Cawenda remains a general reminder tool and does not advise users how to handle missed medication doses.

## Final Design

Each `ReminderTask` stores an optional whole-hour repeat interval and an optional cadence anchor. `reminderFiresAt` remains the time of the currently scheduled occurrence. Keeping the anchor separate prevents snoozing or late completion from shifting the series.

The capture window places a compact **Repeat** control after **Tomorrow**. Its options are **Does not repeat**, common hourly presets, and **Custom…**. The edit sheet exposes the same recurrence settings for existing reminders.

When **Done** is selected for a repeating reminder, Cawenda resets its checklist, clears its fired state, keeps it active, and calculates the first cadence occurrence strictly after the current time. For example, an eight-hour series anchored at 8:00 AM remains 8:00 AM, 4:00 PM, and midnight even if the 8:00 AM occurrence is completed late.

**Stop Repeating** is available from the reminder context menu and edit sheet. It completes the series and moves the reminder to History. Deleting continues to remove the reminder entirely. V1 does not add occurrence counts, end dates, a separate skip action, or per-occurrence History entries.

## Reliability and Testing

- Verify legacy JSON compatibility and persistence across relaunches.
- Verify fixed-cadence advancement and multiple missed intervals.
- Verify snoozing does not move the cadence anchor.
- Verify checklist reset and fired-state reset.
- Verify **Stop Repeating** and ordinary one-time completion.
- Verify recurrence creation, editing, and the control's position after **Tomorrow**.
- Treat missing or invalid recurrence data as non-repeating.

## Decision Log

- Chose fixed cadence instead of completion-relative recurrence to preserve predictable scheduled times.
- Chose one overdue occurrence instead of stacking every missed occurrence to prevent alert floods.
- Chose manual **Stop Repeating** instead of counts or end dates to keep V1 small.
- Chose only **Done** and **Stop Repeating**; a separate skip-occurrence action is explicitly excluded.
- Chose a separate cadence anchor so snoozing cannot silently shift future occurrences.
- Kept medication handling outside product logic because missed-dose instructions vary by medicine.
