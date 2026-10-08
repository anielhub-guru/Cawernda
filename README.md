<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/icon_128x128.png" alt="Cawernda Logo" width="128" height="128">
</p>

<h1 align="center">Cawernda</h1>

<p align="center">
  <strong>A minimalist, natural language-powered reminder app for macOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-15.0+-black?style=for-the-badge&logo=apple" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?style=for-the-badge&logo=swift" alt="Swift 6.0">
</p>

---

## Reminder-first V1 fork

Cawernda is a reminder-first fork of [RemindMe](https://github.com/samirpatil2000/remindme), retaining its MIT license and narrowing the experience around reliable reminders rather than timers and focus tooling:

- Paste a heading followed by bullets, numbered steps, or Markdown checkboxes to create a reminder with checkable items.
- Choose an exact date and time, or use the one-hour and tomorrow shortcuts.
- Review open reminders in **Overdue**, **Today**, **Next 7 Days**, and **Later** sections from the menu bar.
- Toggle checklist items independently without completing the parent reminder.
- Existing saved reminders decode safely with an empty checklist after the model upgrade.

Example paste:

```markdown
### Job Applications
- [ ] Review suggested job roles
- [ ] Identify suitable roles
- [ ] Apply for selected roles
- [ ] Record applications submitted
```

Press `⌘⇧Space` to open capture and `⌘↩` to save. The upstream auto-updater is disabled in this fork so it cannot replace modified builds with upstream releases.

For a local test build, run `bash package_local.sh`. The ad-hoc-signed app is created at `artifacts/Cawernda.app` and does not replace any app in `/Applications`.

---

### ✨ Why Cawernda?
- **Ultra-lightweight** — Built with SwiftUI for modern macOS performance, minimal RAM/CPU usage.
- **Natural Language Parsing** — Set reminders with ease using tokens like `@1m`, `@10m`, `@1h`.
- **Dual Input Modes** — Type your time to get smart suggestions, or select custom durations directly from an elegant visual TimePicker UI.
- **Stay Awake** — Keep your Mac awake from the Status Board using native macOS power assertions (with options to keep screen awake, or stay awake when laptop lid closes).
- **Periodic Breaks** — Build healthy work habits with automated periodic focus/eye breaks showing a custom Sinclair/Cos-animated countdown overlay.
- **Low Battery Alert** — Get notified when the MacBook battery drops below a customizable threshold (10%, 15%, 20%, 30%) on battery power, automatically updating with each 1% drop and stopping once plugged in.
- **Focus Analytics** — Track your productivity with aggregate focus time and snooze counts natively in the Status Board.
- **Global Hotkey** — Use a customizable global shortcut to instantly bring up the command window from anywhere.
- **Todoist-inspired Design** — Clean, functional interface, beautiful hover-reveal UI for completed tasks, and elegant popovers.
- **Auto Launch** — Enable launch at login so your reminder system is always ready when you are.
- **Privacy First** — Everything stays on your Mac, no cloud syncing, no data tracking.
- **Native Experience** — Deeply integrated with macOS notifications and menu bar tools.

---

### 📥 Local build

Run `bash package_local.sh`, then open `artifacts/Cawernda.app`. This development bundle is ad-hoc signed and remains separate from the original RemindMe app.

---

## 🚀 Getting Started

1. **Launch** Cawernda — it will appear in your menu bar with a clock icon.
2. **Press ⌘⇧Space** from any app to open the Command Window.
3. **Type your reminder** (e.g., `Call Mom @10m` or `Check the oven @5m`).
4. **Press Enter** to set the reminder.
5. **Open the Status Board** from the menu bar to review reminders, take a break, or start **Stay Awake** for `5m`, `10m`, `30m`, `1h`, `2h`, `4h`, or indefinitely.
6. **Receive a native notification** when the timer expires!

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧Space` | Open command window |
| `↵` Enter | Save reminder |
| `⎋` Esc | Close command window |
| `⌘ ,` | Open Settings |

---

## Screenshots 

<table>
  <tr>
    <td rowspan="4" valign="top">
      <img src="https://github.com/user-attachments/assets/dc287118-4aa1-472f-a267-31d528d26fa1" alt="Status Board: All Clear & Focus Summary" width="380"/>
      <br/>
      <sup>status board — glance, don't manage</sup>
      <br/><br/><br/>
      <img src="https://github.com/user-attachments/assets/90037b35-11b7-4b4b-b41e-7b5f355b3b4d" alt="Low Battery Alert Custom Popup" width="380" />
      <br/>
      <sup>low battery alert — custom popup</sup>
    </td>
    <td>
      <img src="https://github.com/user-attachments/assets/b1d92e4c-f5ad-45a5-b16c-ce893cf2631f" alt="Quick Reminder Entry with Smart Time Suggestion" width="560"/>
      <br/>
      <sup>type anything. smart default: 5 minutes.</sup>
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/ea8a85fe-f4fc-4584-8713-33c2abc5ae8d" alt="Natural Language Input with @ Time Tokens" width="560"/>
      <br/>
      <sup>use <code>@10m</code> or <code>@1h</code> for precise timing</sup>
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/beb0d90f-93cc-423c-9aae-db9b0e4e83bb" alt="Visual TimePicker for Custom Durations" width="560"/>
      <br/>
      <sup>or pick from presets. custom down to the second.</sup>
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/c85e63f4-1ec0-4b52-899b-d8c129edc9c7" alt="Actionable Reminder Notification with Snooze Options" width="400"/>
      <br/>
      <sup>it fires. mark done, extend, or snooze.</sup>
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/e3dee24b-aad8-4675-81a8-e0aa90b1b3d3" alt="Actionable Reminder Notification with Snooze Options" width="400"/>
      <br/>
      <sup>Run with lip closed</sup>
    </td>
  </tr>
</table>


## 🛠️ Building from Source

```bash
# Open in Xcode
open Package.swift

# Build and run
# Press ⌘R in Xcode
```

### Requirements
- macOS 15.0 or later
- Xcode 16.0 or later
- Swift 6.0

---

## 📁 Project Structure

```
Cawernda/
├── App/
│   ├── AppDelegate.swift       # App lifecycle, hotkey & battery listener
│   └── CawerndaApp.swift       # Swift entry point
├── Managers/
│   ├── BatteryManager.swift    # IOKit battery level & charger monitoring
│   ├── CaffeinateManager.swift # Stay Awake process lifecycle
│   ├── HotkeyManager.swift     # Global keyboard shortcuts (Carbon API)
│   ├── NotificationManager.swift # macOS notification delivery
│   └── PermissionsManager.swift # Notification permissions handler
├── Parser/
│   ├── ReminderParser.swift    # Natural language parsing logic
│   └── TimeToken.swift         # Duration token definitions (@1m, etc.)
├── Models/
│   └── Task.swift             # Core reminder task models
├── Settings/
│   └── SettingsView.swift      # Settings layout and global hotkey capture
└── Views/
    ├── CommandWindow/         # Quick command window entry UI
    ├── LockOverlay/           # Fullscreen timer lock screens
    ├── MenuBar/               # Status board menu item & popover
    └── Popups/
        ├── PopupManager.swift # Stacking custom alerts controller
        ├── PopupStackView.swift # Custom reminder alert UI card
        └── BatteryPopupView.swift # Custom low battery warning card
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

---

## 📄 License

MIT License — feel free to use this project however you like.

---

<p align="center">
  Made with ❤️ for macOS
</p>
# Cawernda
