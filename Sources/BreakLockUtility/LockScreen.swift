import Foundation

enum ScreenLocker {
    /// Locks the session (login screen) and optionally turns off the display.
    /// - Parameter displaySleep: If true, runs `pmset displaysleepnow` after locking so the screen blanks.
    static func lockNow(displaySleep: Bool = true) {
        // Lock session (shows login screen).
        let cgSessionPath = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        let lockProcess = Process()
        lockProcess.executableURL = URL(fileURLWithPath: cgSessionPath)
        lockProcess.arguments = ["-suspend"]

        do {
            try lockProcess.run()
            lockProcess.waitUntilExit()
        } catch {
            // Best-effort: do nothing if unavailable.
        }

        // Optionally turn off the display (blank screen).
        if displaySleep {
            let pmset = Process()
            pmset.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            pmset.arguments = ["displaysleepnow"]
            try? pmset.run()
        }
    }
}

