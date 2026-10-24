# Alarm Popup Subtasks

## Understanding summary

- Plain reminders retain the existing compact alarm card.
- Reminders with subtasks show outstanding work directly in the alarm.
- Incomplete subtasks are prioritized while completed subtasks remain available.
- Users can check or uncheck subtasks without leaving the alarm.
- Long checklists scroll inside the card instead of expanding without limit.
- Parent reminder actions and snooze behavior remain unchanged.

## Assumptions

- Subtask changes persist locally through the existing `TaskStore` storage path.
- Completing all subtasks does not automatically complete the parent reminder.
- Checklist cards use a capped height and additional simultaneous alarms use the existing overflow queue.
- Nested subtasks, text editing, and reordering are outside this change.

## Final design

`PopupStackView` receives a checklist and a toggle callback. An empty checklist follows the original 380-by-180 rendering path. A non-empty checklist uses a taller card with a progress summary, a remaining-first list, and a collapsed completed section. The checklist region scrolls internally, and toggles update local view state immediately before persisting through `TaskStore.toggleChecklistItem`.

`PopupManager` selects the card height from the reminder content, lays out mixed-height cards, and places additional alarms in the pending queue when another visible card would exceed the usable screen height.

## Decision log

- Chose a remaining-first list over a single undifferentiated checklist because alarms should emphasize unfinished work.
- Kept completed subtasks in a collapsed section so progress remains inspectable without dominating the card.
- Allowed direct checking and unchecking because the alarm is already the point of action.
- Used internal scrolling and screen-aware overflow to keep long or simultaneous reminders on-screen.
- Preserved the compact card exactly for reminders without subtasks.
