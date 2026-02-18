import Foundation
import SwiftUI
import AppKit

@MainActor
final class BreakScheduler: ObservableObject {
    enum State: String {
        case idle
        case running
        case paused
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var nextLockAt: Date?
    @Published private(set) var nextReminderAt: Date?

    private weak var settings: SettingsStore?

    private var reminderWorkItem: DispatchWorkItem?
    private var lockWorkItem: DispatchWorkItem?
    private var isSkipNextBreakArmed = false
    private var awaitingUnlock = false
    private var unlockObserver: NSObjectProtocol?

    func bind(settings: SettingsStore) {
        self.settings = settings
        print("bind settings called")
        Task { await Notifier.ensureAuthorized() }

        // Observe screen unlock to restart the interval (Option A behavior).
        if unlockObserver == nil {
            let center = DistributedNotificationCenter.default()
            unlockObserver = center.addObserver(
                forName: NSNotification.Name("com.apple.screenIsUnlocked"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    guard self.state == .running, self.awaitingUnlock, let settings = self.settings else { return }
                    // Restart a full work interval from the unlock time.
                    self.awaitingUnlock = false
                    self.scheduleNewInterval(from: Date(), settings: settings)
                }
            }
        }
    }
    
    func applySettingsChanged() {
        guard let settings else { return }
        guard state == .running else { return }
        // If we're awaiting unlock, do nothing; next interval will be scheduled on unlock.
        if awaitingUnlock {
            return
        }
        cancelScheduledWork()
        scheduleNewInterval(from: Date(), settings: settings)
    }

    deinit {
        if let token = unlockObserver {
            DistributedNotificationCenter.default().removeObserver(token)
        }
    }

    func startOrResume() {
        guard let settings else { return }

        switch state {
        case .idle:
            awaitingUnlock = false
            scheduleNewInterval(from: Date(), settings: settings)
            state = .running
        case .paused:
            // Resume by scheduling a fresh full interval from now (simple + predictable).
            awaitingUnlock = false
            scheduleNewInterval(from: Date(), settings: settings)
            state = .running
        case .running:
            break
        }
    }

    func pause() {
        guard state == .running else { return }
        cancelScheduledWork()
        awaitingUnlock = false
        state = .paused
    }

    func skipNextBreak() {
        guard let settings else { return }
        guard state == .running else { return }

        // Arm skip once; cancel current interval and restart a full interval from now.
        isSkipNextBreakArmed = true
        awaitingUnlock = false
        cancelScheduledWork()
        scheduleNewInterval(from: Date(), settings: settings)
    }

    func quit() {
        cancelScheduledWork()
        NSApp.terminate(nil)
    }

    private func scheduleNewInterval(from start: Date, settings: SettingsStore) {
        cancelScheduledWork()

        let interval = settings.breakInterval
        // Reminder is user-controlled but may not exceed 1 minute less than the interval.
        let maxLead = max(0, interval - 60)
        let reminderLead = min(settings.reminderLead, maxLead)

        let lockAt = start.addingTimeInterval(interval)
        nextLockAt = lockAt

        if reminderLead > 0 {
            let reminderAt = lockAt.addingTimeInterval(-reminderLead)
            nextReminderAt = reminderAt
            scheduleReminder(at: reminderAt, lockAt: lockAt, leadSeconds: reminderLead)
        } else {
            nextReminderAt = nil
        }

        scheduleLock(at: lockAt, breakDuration: settings.breakDuration)
    }

    private func scheduleReminder(at date: Date, lockAt: Date, leadSeconds: TimeInterval) {
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.state == .running else { return }

            // If user pressed "Skip Next Break", we still run a full interval and should not
            // show a reminder for the *skipped* break (because it no longer exists).
            // Since skip restarts the interval immediately, this reminder will naturally
            // correspond to the new interval. No special-case needed here.

            let mins = Int(round(leadSeconds / 60))
            let title = "Upcoming break"
            let body = mins <= 1
                ? "Break in 1 minute. Get ready to look away from the screen."
                : "Break in \(mins) minutes. Get ready to look away from the screen."
            Notifier.postNow(title: title, body: body)
        }

        reminderWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, date.timeIntervalSinceNow), execute: work)
    }

    private func scheduleLock(at date: Date, breakDuration: TimeInterval) {
        let work = DispatchWorkItem { [weak self] in
            guard let self, let settings = self.settings else { return }
            guard self.state == .running else { return }

            if self.isSkipNextBreakArmed {
                // Apply skip once.
                self.isSkipNextBreakArmed = false
                self.awaitingUnlock = false
                self.scheduleNewInterval(from: Date(), settings: settings)
                return
            }

            // Notify user on lock screen: they can unlock anytime; show suggested break time.
            let breakMins = max(1, Int(round(breakDuration / 60)))
            let breakMsg = breakMins == 1
                ? "Unlock anytime with your password. Suggested break: 1 minute."
                : "Unlock anytime with your password. Suggested break: \(breakMins) minutes."
            Notifier.postNow(title: "Break started", body: breakMsg)

            // Lock now (and optionally turn off display).
            ScreenLocker.lockNow(displaySleep: settings.displaySleepWhenLocking)

            // Option A: Do not schedule the next interval based on break duration.
            // Wait for screen unlock to restart from the unlock time.
            self.awaitingUnlock = true
            self.nextLockAt = nil
            self.nextReminderAt = nil
            self.reminderWorkItem = nil
            self.lockWorkItem = nil
        }

        lockWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, date.timeIntervalSinceNow), execute: work)
    }

    private func cancelScheduledWork() {
        reminderWorkItem?.cancel()
        lockWorkItem?.cancel()
        reminderWorkItem = nil
        lockWorkItem = nil
        nextLockAt = nil
        nextReminderAt = nil
    }
}

