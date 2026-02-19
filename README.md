# Break Lock (macOS menu bar app)

A lightweight macOS **menu bar** utility that locks your screen at configurable intervals to encourage regular breaks.

## Features

- **Menu bar controls**: Start/Resume, Pause, Skip Next Break, Settings, Quit
- **Configurable** (via Settings window):
  - Break interval (minutes)
  - Break duration (minutes — advisory, shown in messages only)
  - Reminder time before lock (minutes)
  - Turn off display when locking
- Gentle **reminder notification** before each lock (shown even when the app is in the foreground)
- Locks screen via `CGSession -suspend` with automatic fallback to `Cmd+Ctrl+Q` on newer macOS versions
- Optional **display sleep** after locking
- Timer precision aligned to **whole minutes** — starting at 7:44:37 counts from 7:44:00
- Custom **app icon** (SF Symbol `lock.circle.fill`) shown in notifications

## Prerequisites

- macOS 13.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — install with `brew install xcodegen`

## Setup & Run

The project uses **XcodeGen** to generate the `.xcodeproj` from `project.yml`.

```bash
# 1. Install XcodeGen (one-time)
brew install xcodegen

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode
open BreakLockUtility.xcodeproj
```

Then select the **BreakLockUtility** scheme and press **Run** (Cmd+R).

> **Important**: Always open `BreakLockUtility.xcodeproj`, **not** the folder. Opening the folder uses Swift Package Manager mode, which builds a bare executable without an `.app` bundle — notifications and other bundle-dependent features will silently fail.

### When to regenerate

Run `xcodegen generate` only when you:
- Add, remove, or rename `.swift` files
- Change build settings in `project.yml`

Day-to-day code edits just need Cmd+R in Xcode.

## How it works

### Menu bar

- The app runs as a **menu-bar-only utility** (no Dock icon, no app switcher entry).
- Click the **lock.circle** icon in the menu bar to access all controls.
- **Settings...** opens a standalone window to configure intervals.

### Timer

1. Press **Start / Resume** to begin.
2. The app schedules a lock at `now + break interval` (rounded to the current minute).
3. A **reminder notification** fires before the lock (configurable lead time).
4. At lock time, the screen locks immediately.
5. After you **unlock manually** (password / Touch ID), the next interval starts automatically.

### Locking and unlocking

When a break starts, the app:

1. Locks the session via `CGSession -suspend`. If that binary doesn't exist (macOS 14+), falls back to simulating **Cmd+Ctrl+Q** via AppleScript (requires one-time Accessibility permission).
2. If **Turn off display when locking** is enabled: runs `pmset displaysleepnow`.

**Unlocking** is always manual — macOS does not allow apps to auto-unlock the screen.

**Break duration** is advisory only. It is used in messages to suggest how long to rest. You can unlock at any time.

### Permissions

- **Notifications**: macOS prompts on first launch. If denied, go to **System Settings > Notifications > Break Lock** and enable.
- **Notifications show "Notification" instead of content?** Set **Show Previews > Always** in System Settings > Notifications (both the app-specific and system-wide setting).
- **Accessibility** (only if CGSession fallback is used): macOS will prompt to allow the app to send keystrokes. Grant in **System Settings > Privacy & Security > Accessibility**.
- **App Sandbox is disabled** so `Process()` calls (CGSession, pmset, osascript) work.

## Distributing the app

To share the app with someone without Xcode:

```bash
# 1. Archive in Xcode
#    Product > Archive (or Cmd+Shift+B with Release config)

# 2. Export from the Organizer
#    Window > Organizer > select archive > Distribute App > Copy App

# 3. The exported .app can be shared directly or wrapped in a DMG:
hdiutil create -volname "Break Lock" -srcfolder /path/to/BreakLockUtility.app -ov BreakLock.dmg
```

Recipients may need to right-click > Open on first launch to bypass Gatekeeper (since the app is not notarized). For wider distribution, consider signing with a Developer ID and notarizing via `xcrun notarytool`.

## Project structure

```
project.yml                    # XcodeGen spec (source of truth for .xcodeproj)
Package.swift                  # SPM manifest (for compatibility, not primary build)
BreakLockUtility/Info.plist    # App Info.plist
Sources/BreakLockUtility/
  BreakLockUtilityApp.swift    # @main App, menu bar scene, icon setup
  BreakScheduler.swift         # Timer scheduling, lock triggering, unlock observation
  LockScreen.swift             # Screen lock (CGSession + AppleScript fallback)
  MenuContentView.swift        # Menu bar dropdown UI
  AppSettingsView.swift        # Settings window + SettingsWindowController
  Notifications.swift          # UNUserNotificationCenter wrapper
  SettingsStore.swift          # @AppStorage-backed preferences
```

