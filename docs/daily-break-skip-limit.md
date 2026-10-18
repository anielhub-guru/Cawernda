# Daily Break Skip Limit

## Understanding Summary

- Periodic breaks should remain skippable in emergencies without making accidental dismissal easy.
- Skip enforcement is optional and enabled by default.
- Each user starts with two configurable skips per calendar day.
- Completing the countdown records a rest; dismissing early records a skip only while enforcement is enabled.
- The overlay displays today’s completed rests and remaining skips without adding visual clutter.

## Assumptions

- Daily counters use the Mac’s current local calendar day.
- Disabling enforcement restores unlimited dismissal and does not consume the tracked allowance.
- macOS Force Quit remains available as an operating-system-level emergency exit.
- Escape and Delete refer to key codes 53 and 51 on macOS keyboards.

## Final Design

Settings includes **Limit Daily Break Skips** and a **Daily Skip Allowance** from 0 through 10, defaulting to two. When enforcement is active, Cawenda stores completed-rest and skipped-break counts separately and resets each count when the local date changes.

The overlay shows `Rests today: N • Skips remaining: N`. A skip requires either `Esc, Esc` or `Delete, Delete` within two seconds. Mixed keys, late second presses, and single presses do not dismiss the overlay. When no skips remain, both keys are consumed but ignored until the countdown completes.

## Decision Log

- Chose a daily maximum rather than a minimum because the feature limits avoidance.
- Chose two skips as the default allowance.
- Chose an optional toggle to support users who do not want enforced breaks.
- Chose a same-key double press within two seconds to prevent accidental dismissal.
- Added Delete as an alternative for keyboards with an unreliable or inaccessible Escape key.
- Kept the status and instruction copy to one line each to preserve the uncluttered overlay.
