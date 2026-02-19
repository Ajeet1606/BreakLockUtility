import Foundation
import UserNotifications

/// Delegate so notifications are shown even when the app is in the foreground.
private final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

private let notificationDelegate = NotificationDelegate()

enum Notifier {
    private static var hasValidBundle: Bool {
        let path = Bundle.main.bundlePath
        if path.hasSuffix(".app") { return true }
        if Bundle.main.bundleIdentifier != nil { return true }
        return false
    }

    /// Call once at app launch to request permission and install the delegate.
    static func ensureAuthorized() async {
        guard hasValidBundle else {
            print("[Notifier] Skipping — no valid .app bundle")
            return
        }
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        let settings = await center.notificationSettings()
        print("[Notifier] authorization status:", settings.authorizationStatus.rawValue)
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                print("[Notifier] Permission granted:", granted)
            } catch {
                print("[Notifier] Permission request error:", error)
            }
        case .denied:
            print("[Notifier] Notifications denied by user. Enable in System Settings > Notifications.")
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            break
        }
    }

    static func postNow(title: String, body: String) {
        guard hasValidBundle else { return }
        let center = UNUserNotificationCenter.current()

        // Always ensure the delegate is set so banners show while the app is active.
        center.delegate = notificationDelegate

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request) { error in
            if let error {
                print("[Notifier] Failed to post notification:", error)
            } else {
                print("[Notifier] Notification posted:", title)
            }
        }
    }
}

