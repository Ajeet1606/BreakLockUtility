import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var scheduler: BreakScheduler

    @State private var showSettings = false

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
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(scheduler)
                .frame(width: 360, height: 260)
                .padding()
        }
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
            Button("Settings…") { showSettings = true }
                .buttonStyle(.borderless)

            Text("Interval: \(settings.breakIntervalMinutes) min • Break: \(settings.breakDurationMinutes) min • Reminder: \(settings.reminderMinutesBefore) min")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var scheduler: BreakScheduler

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.title3)

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    Text("Break interval")
                    Stepper(value: $settings.breakIntervalMinutes, in: 1...480) {
                        Text("\(settings.breakIntervalMinutes) minutes")
                    }
                }

                GridRow {
                    Text("Break duration")
                    Stepper(value: $settings.breakDurationMinutes, in: 1...60) {
                        Text("\(settings.breakDurationMinutes) minutes")
                    }
                }

                GridRow {
                    Text("Reminder before lock")
                    Stepper(value: $settings.reminderMinutesBefore, in: 0...30) {
                        Text("\(settings.reminderMinutesBefore) minutes")
                    }
                }

                GridRow {
                    Text("Turn off display when locking")
                    Toggle("", isOn: $settings.displaySleepWhenLocking)
                        .labelsHidden()
                }
            }

            Text("Unlock anytime with your password. The next work interval starts when you unlock. Break duration is advisory (used in messages only).")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Changing settings affects the next scheduled interval. To apply immediately, Pause then Start/Resume.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Close") { NSApp.keyWindow?.close() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}

