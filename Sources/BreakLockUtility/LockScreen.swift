import Foundation

enum ScreenLocker {
    /// Locks the session (login screen) and optionally turns off the display.
    /// - Parameter displaySleep: If true, runs `pmset displaysleepnow` after locking so the screen blanks.
    static func lockNow(displaySleep: Bool = true) {
        var locked = false

        // Method 1: CGSession -suspend (works on macOS 12 and most of 13/14).
        let cgSessionPath = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        if FileManager.default.fileExists(atPath: cgSessionPath) {
            let lockProcess = Process()
            lockProcess.executableURL = URL(fileURLWithPath: cgSessionPath)
            lockProcess.arguments = ["-suspend"]
            do {
                try lockProcess.run()
                lockProcess.waitUntilExit()
                if lockProcess.terminationStatus == 0 { locked = true }
            } catch {
                // Fall through to Method 2.
            }
        }

        // Method 2: Simulate Cmd+Ctrl+Q via AppleScript (macOS 13+).
        // On first use macOS will prompt the user to grant Accessibility permission
        // to the app (System Settings > Privacy & Security > Accessibility).
        if !locked {
            let script = Process()
            script.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            script.arguments = [
                "-e",
                "tell application \"System Events\" to keystroke \"q\" using {command down, control down}"
            ]
            do {
                try script.run()
                script.waitUntilExit()
            } catch {
                // Best-effort.
            }
        }

        // Optionally turn off the display.
        if displaySleep {
            // Brief pause so the lock engages before blanking the display.
            usleep(300_000) // 0.3 s
            let pmset = Process()
            pmset.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            pmset.arguments = ["displaysleepnow"]
            try? pmset.run()
        }
    }
}

