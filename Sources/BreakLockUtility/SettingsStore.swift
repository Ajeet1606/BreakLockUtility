import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("breakIntervalMinutes") var breakIntervalMinutes: Int = 5
    @AppStorage("breakDurationMinutes") var breakDurationMinutes: Int = 2
    @AppStorage("reminderMinutesBefore") var reminderMinutesBefore: Int = 4
    @AppStorage("displaySleepWhenLocking") var displaySleepWhenLocking: Bool = true

    var breakInterval: TimeInterval { TimeInterval(max(1, breakIntervalMinutes)) * 60 }
    var breakDuration: TimeInterval { TimeInterval(max(1, breakDurationMinutes)) * 60 }
    var reminderLead: TimeInterval { TimeInterval(max(0, reminderMinutesBefore)) * 60 }
}

