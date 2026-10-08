# Daily Planning Prompt

## Understanding

- Cawernda should remain useful when there are no active reminders.
- Once per local calendar day, the first launch, login, or wake should perform a planning check.
- If the reminder list is empty, the existing startup overlay should ask, “What do you want to do today?”
- The primary action opens Cawernda’s quick reminder-entry window.
- Active reminders satisfy the daily check and retain the existing review behavior.
- The feature remains local-first and does not integrate with Apple Calendar or become a planner.

## Assumptions

- The last completed check is stored in `UserDefaults`.
- Calendar-day comparison uses the Mac’s current calendar and time zone.
- A busy Cawernda interface defers the check until it is free.
- Crossing midnight by itself does not display the prompt.
- No new user preference is needed for the first version.

## Final Design

The startup overlay supports active-reminder and daily-planning content modes. On launch or wake, a pure policy checks whether today has already been handled. Active reminders mark the day handled; an empty list presents the planning prompt; a busy interface leaves the check pending for the existing periodic timer to retry.

The daily prompt provides **Add a reminder**, **Not now**, and Escape. Adding a reminder dismisses the overlay and focuses the existing quick-entry window. Dismissing the prompt prevents another appearance that day.

## Decision Log

- Reused the existing full-screen startup overlay instead of adding another window controller.
- Chose local calendar days instead of a rolling 24-hour interval.
- Chose Cawernda quick entry as the only primary destination.
- Kept the daily prompt independent from the recurring active-reminder review preference.
- Excluded Apple Calendar, planning features, statistics, accounts, and synchronization.
