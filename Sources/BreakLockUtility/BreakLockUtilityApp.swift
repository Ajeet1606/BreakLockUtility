import SwiftUI
import AppKit

@main
struct BreakLockUtilityApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var scheduler = BreakScheduler()

    init() {
        // Prevent Dock icon + app switcher presence (menu-bar style utility).
        NSApplication.shared.setActivationPolicy(.accessory)

        // Set app icon from SF Symbol so notifications show the lock icon.
        if let icon = Self.renderAppIcon() {
            NSApplication.shared.applicationIconImage = icon
        }

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

    /// Renders the lock.circle.fill SF Symbol into a proper bitmap image for the app icon.
    private static func renderAppIcon() -> NSImage? {
        let size: CGFloat = 256
        let config = NSImage.SymbolConfiguration(pointSize: size * 0.8, weight: .regular)
            .applying(.init(paletteColors: [.white, NSColor.systemBlue]))
        guard let symbol = NSImage(systemSymbolName: "lock.circle.fill", accessibilityDescription: "Break Lock")?
            .withSymbolConfiguration(config) else { return nil }

        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size),
            pixelsHigh: Int(size),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        bitmapRep.size = NSSize(width: size, height: size)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)

        // Center the symbol in the bitmap.
        let symbolSize = symbol.size
        let x = (size - symbolSize.width) / 2
        let y = (size - symbolSize.height) / 2
        symbol.draw(in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height))

        NSGraphicsContext.restoreGraphicsState()

        let icon = NSImage(size: NSSize(width: size, height: size))
        icon.addRepresentation(bitmapRep)
        icon.isTemplate = false
        return icon
    }
}

