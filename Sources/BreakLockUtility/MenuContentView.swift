import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var scheduler: BreakScheduler

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusSection
            Divider()
            settingsSection
            Divider()
            controlsSection
            Divider()
            Button("Send Test Notification") {
                Notifier.postNow(title: "Test", body: "Hello from BreakLockUtility")
            }
            Divider()
            Button("Quit") { scheduler.quit() }
        }
        .padding(.vertical, 6)
        .frame(minWidth: 260)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Break Lock Utility")
                .font(.headline)

            Text("State: \(scheduler.state.rawValue.capitalized)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let next = scheduler.nextLockAt, scheduler.state == .running {
                Text("Next lock: \(next.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Next lock: —")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(scheduler.state == .running ? "Running" : "Start / Resume") {
                scheduler.startOrResume()
            }
            .disabled(scheduler.state == .running)

            Button("Pause") { scheduler.pause() }
                .disabled(scheduler.state != .running)

            Button("Skip Next Break") { scheduler.skipNextBreak() }
                .disabled(scheduler.state != .running)
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button("Settings…") {
                SettingsWindowController.shared.open(settings: settings, scheduler: scheduler)
            }
            .buttonStyle(.borderless)

            Text("Interval: \(settings.breakIntervalMinutes) min • Break: \(settings.breakDurationMinutes) min • Reminder: \(settings.reminderMinutesBefore) min")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

