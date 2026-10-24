import AppKit

@main
enum DoodlePinMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = StatusIcon.make()
        statusItem.button?.toolTip = "DoodlePin"
        let menu = NSMenu()
        menu.delegate = MenuBuilder.shared
        statusItem.menu = menu

        PetManager.shared.start()

        let prefs = Prefs.shared
        if !prefs.hasLaunchedBefore {
            prefs.hasLaunchedBefore = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                PetManager.shared.pets.first?.say("Psst! Find me in the\nmenu bar up top ↗", for: 8)
            }
        }
    }

    /// Opening the app again (e.g. from Finder or Launchpad) shows Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindowController.shared.show()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        PetManager.shared.savePositions()
    }
}

/// A tiny blob face for the menu bar.
enum StatusIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.set()
            let body = NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 14, height: 13))
            body.lineWidth = 1.6
            body.stroke()
            NSBezierPath(ovalIn: NSRect(x: 5.6, y: 8, width: 2.3, height: 3)).fill()
            NSBezierPath(ovalIn: NSRect(x: 10.1, y: 8, width: 2.3, height: 3)).fill()
            let smile = NSBezierPath()
            smile.move(to: NSPoint(x: 6.5, y: 6))
            smile.curve(to: NSPoint(x: 11.5, y: 6), controlPoint1: NSPoint(x: 7.5, y: 4.2), controlPoint2: NSPoint(x: 10.5, y: 4.2))
            smile.lineWidth = 1.3
            smile.lineCapStyle = .round
            smile.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}
