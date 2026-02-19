import SwiftUI
import AppKit

@main
struct BreakLockUtilityApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var scheduler = BreakScheduler()

    init() {
        // Prevent Dock icon + app switcher presence (menu-bar style utility).
        NSApplication.shared.setActivationPolicy(.accessory)

        // Request notification permission immediately at launch,
        // so the delegate is installed before any notification is posted.
        Task { await Notifier.ensureAuthorized() }
    }

    var body: some Scene {
        MenuBarExtra("Break Lock", systemImage: "lock.circle") {
            MenuContentView()
                .environmentObject(settings)
                .environmentObject(scheduler)
                .onAppear {
                    scheduler.bind(settings: settings)
                }
        }
        .menuBarExtraStyle(.menu)
    }
}

