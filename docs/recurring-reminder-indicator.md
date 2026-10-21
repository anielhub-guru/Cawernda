# Recurring Reminder Indicator

## Understanding Summary

- Repeating reminders need to be visibly distinguishable from one-time reminders.
- The indicator combines a repeat symbol with compact text such as `Every 8h`.
- It appears in the active reminder list, alarm popup, and full-screen reminder overlay.
- It sits with existing timing metadata rather than competing with the reminder title.
- Secondary styling keeps the indicator clear without overpowering overdue status.
- One-time reminders and History remain visually unchanged.
- Scheduling and persistence behavior are outside this change.

## Assumptions

- The indicator uses an available macOS repeat system symbol.
- All intervals use the compact `Every Xh` format, including `Every 1h`.
- Accessibility reads the expanded phrase `Repeats every X hours`.
- No new colors, animations, settings, or model fields are needed.
- The change has no material performance, privacy, reliability, scale, or maintenance impact.

## Final Design

A reusable SwiftUI `RecurrenceIndicator` receives an optional hourly interval. It renders a small repeat icon and `Every Xh` using rounded secondary text. It renders nothing when the interval is absent.

The active reminder row places the indicator after the due-time text and before checklist progress. The alarm popup places it beneath the title beside the fired-time metadata. The full-screen review overlay places it after the due-time text. Existing spacing remains unchanged for one-time reminders.

## Testing

- Verify compact interval formatting.
- Verify the expanded accessibility label.
- Verify one-time reminders omit the indicator.
- Verify alarm popup data wiring.
- Run the complete regression suite and release build.

## Decision Log

- Chose icon plus `Every Xh` over a colored badge because it communicates recurrence and frequency without relying on color.
- Chose all active-reminder surfaces over the menu list alone for consistent recognition.
- Chose a shared component over three inline implementations to prevent presentation drift.
- Excluded History because a stopped recurring series is no longer active.
- Excluded animation and new accent colors to preserve Cawenda's restrained visual hierarchy.
