import SwiftUI
import AppKit

struct AppSettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var scheduler: BreakScheduler

    // Editable copies (so Cancel discards changes)
    @State private var intervalMinutes: Int = 0
    @State private var breakMinutes: Int = 0
    @State private var reminderBeforeMinutes: Int = 0
    @State private var displaySleep: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.title3)

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    Text("Break interval")
                    Stepper(value: $intervalMinutes, in: 1...480) {
                        Text("\(intervalMinutes) minutes")
                    }
                }

                GridRow {
                    Text("Break duration")
                    Stepper(value: $breakMinutes, in: 1...60) {
                        Text("\(breakMinutes) minutes")
                    }
                }

                GridRow {
                    Text("Reminder before lock")
                    Stepper(value: $reminderBeforeMinutes, in: 0...max(0, intervalMinutes - 1)) {
                        Text("\(reminderBeforeMinutes) minutes")
                    }
                }

                GridRow {
                    Text("Turn off display when locking")
                    Toggle("", isOn: $displaySleep)
                        .labelsHidden()
                }
            }

            Text("Unlock anytime with your password. The next work interval starts when you unlock. Break duration is advisory (used in messages only).")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Changing settings affects the next scheduled interval. Press Save to apply now; or Cancel to discard changes.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel") { closeWindow() }
                Button("Save") { saveAndApply() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 380, height: 280)
        .padding()
        .onAppear(perform: loadFromStore)
        .onChange(of: intervalMinutes) { newValue in
            let maxReminder = max(0, newValue - 1)
            if reminderBeforeMinutes > maxReminder {
                reminderBeforeMinutes = maxReminder
            }
        }
    }

    private func loadFromStore() {
        intervalMinutes = settings.breakIntervalMinutes
        breakMinutes = settings.breakDurationMinutes
        reminderBeforeMinutes = settings.reminderMinutesBefore
        displaySleep = settings.displaySleepWhenLocking
    }

    private func saveAndApply() {
        settings.breakIntervalMinutes = intervalMinutes
        settings.breakDurationMinutes = breakMinutes
        settings.reminderMinutesBefore = reminderBeforeMinutes
        settings.displaySleepWhenLocking = displaySleep
        scheduler.applySettingsChanged()
        closeWindow()
    }

    private func closeWindow() {
        NSApp.keyWindow?.close()
    }
}

// MARK: - Settings Window Controller

/// Opens an NSWindow hosting AppSettingsView.
/// Used because `openWindow(id:)` does not work from `.menuBarExtraStyle(.menu)` context.
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func open(settings: SettingsStore, scheduler: BreakScheduler) {
        // If the window already exists and is visible, just bring it forward.
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = AppSettingsView()
            .environmentObject(settings)
            .environmentObject(scheduler)

        let hostingView = NSHostingView(rootView: view)
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "Break Lock Settings"
        w.contentView = hostingView
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w
    }
}

