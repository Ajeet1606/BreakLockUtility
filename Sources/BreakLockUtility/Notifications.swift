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
    /// Skip notification setup when not running as an app bundle (e.g. SwiftPM executable),
    /// to avoid "bundleProxyForCurrentProcess is nil" from UserNotifications.
    private static var hasValidBundle: Bool {
        // Prefer reliable bundle checks over process arguments.
        let path = Bundle.main.bundlePath
        if path.hasSuffix(".app") { return true }
        // Fallback: if we have a bundle identifier, we're likely running from an app bundle.
        if Bundle.main.bundleIdentifier != nil { return true }
        return false
    }

    static func ensureAuthorized() async {
        print("ensureAuthorized invoked, hasValidBundle =", hasValidBundle)
        let bundle = Bundle.main
        print("Bundle path:", bundle.bundlePath)
        print("Bundle identifier:", bundle.bundleIdentifier as Any)
        print("Executable URL:", bundle.executableURL?.path as Any)
        print("Process args first:", ProcessInfo.processInfo.arguments.first ?? "nil")
        guard hasValidBundle else { return }
        print("ensureAuthorized called")
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return
        case .denied:
            return
        case .notDetermined:
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        @unknown default:
            return
        }
    }

    static func postNow(title: String, body: String) {
        guard hasValidBundle else { return }
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        print("postNow called, hasValidBundle =", hasValidBundle, "title:", title)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request, withCompletionHandler: nil)
    }
}

