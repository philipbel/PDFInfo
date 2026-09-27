import Cocoa
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let hostingViewController = NSHostingController(rootView: SettingsView())
            hostingViewController.sizingOptions = [.preferredContentSize]
            let w = NSWindow(contentViewController: hostingViewController)
            w.title = "Settings"
            w.styleMask = [.titled, .closable, .resizable]
            w.isReleasedWhenClosed = false
            window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
