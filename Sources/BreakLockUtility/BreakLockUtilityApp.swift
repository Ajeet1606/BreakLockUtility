import SwiftUI
import AppKit

@main
struct BreakLockUtilityApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var scheduler = BreakScheduler()

    init() {
        // Prevent Dock icon + app switcher presence (menu-bar style utility).
        // This avoids needing LSUIElement in Info.plist.
        NSApplication.shared.setActivationPolicy(.accessory)
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

