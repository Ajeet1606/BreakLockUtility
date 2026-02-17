# BreakLockUtility (macOS menu bar app)

A lightweight macOS **menu bar** utility that locks your screen at configurable intervals to encourage regular breaks.

## Features

- Menu bar controls: **Start/Resume**, **Pause**, **Skip Next Break**, **Settings**
- Configurable:
  - Break interval (minutes)
  - Break duration (minutes)
  - Reminder time before lock (minutes)
- Gentle reminder notification before locking (shown even when the app is focused)
- Locks screen via `CGSession -suspend`; optional **turn off display** when locking (Settings)

## Run (Xcode)

**Use the App target** so the app runs as a proper `.app` bundle and notifications work:

1. Open **`BreakLockUtility.xcodeproj`** in Xcode (not the Swift Package).
2. Select the **BreakLockUtility** scheme and press **Run** (⌘R).

If you open the repo as a Swift Package and run the executable target, you may see a `bundleProxyForCurrentProcess is nil` error; use the `.xcodeproj` to avoid that.

Notes:
- The app sets its activation policy to **accessory** (and `LSUIElement` in Info.plist), so it won’t show a Dock icon.
- The **menu bar icon** is the system SF Symbol **`lock.circle`**.
- To configure **interval, break duration, and reminder**: click the menu bar icon → **Settings…** and adjust the values. Changes apply to the next scheduled interval (or Pause then Start/Resume to apply immediately).
- On first run, macOS will ask for **Notifications** permission (needed for reminders).

## Locking and unlocking

**When a break starts**, the app:

1. Shows a **notification** on the lock screen (or in Notification Center): *"Break started — Unlock anytime with your password. Suggested break: X minutes."* (X is your configured break duration.)
2. Locks the session: `CGSession -suspend` (login screen).
3. If **Turn off display when locking** is on in Settings: runs `pmset displaysleepnow` so the screen blanks.

**Unlocking:** You **unlock manually** by entering your Mac password. macOS does not allow apps to auto-unlock the screen. The app cannot lock the screen for a fixed time—you can unlock whenever you want.

**Break duration** is not “locked for X minutes.” It means: after you unlock, the app will schedule the *next* lock to happen X minutes from when the break started. So if break duration is 2 minutes, the next lock is scheduled 2 minutes after the current lock (you can still unlock immediately and use the Mac; the next lock will occur after the next full work interval).

If macOS blocks locking (rare), ensure the app is allowed under **System Settings → Privacy & Security**.

## Notifications

- Reminders (“Upcoming break”) are requested on first **Start/Resume** and show as banners/sounds.
- They are shown even when the app is in the foreground (notification delegate presents them).
- Run from **BreakLockUtility.xcodeproj** so the app has a valid bundle; otherwise notification APIs are skipped.

