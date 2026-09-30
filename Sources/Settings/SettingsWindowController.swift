import Cocoa
import Sparkle


@MainActor
final class SettingsWindowController: NSWindowController {
    private var updateController: SPUStandardUpdaterController!
    private var windowWasAlreadyShownOnce = false

    override init(window: NSWindow? = nil) {
        super.init(window: window)
    }

    convenience init(updateController: SPUStandardUpdaterController) {
        let tabViewController = SettingsTabViewController()
        tabViewController.tabStyle = .toolbar
        tabViewController.addTabViewItem(
            Self.makeSettingsTabViewItem(
                title: "General",
                symbol: "gear",
                viewController: GeneralSettingsViewController()
            ),
        )
        tabViewController.addTabViewItem(
            Self.makeSettingsTabViewItem(
                title: "Updates",
                symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                viewController: UpdateSettingsViewController(updater: updateController.updater)
            )
        )

        let w = NSWindow(contentViewController: tabViewController)
        w.title = String(localized: "Settings")
        w.styleMask = [.titled, .closable]
        w.isReleasedWhenClosed = false

        self.init(window: w)
        self.updateController = updateController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        // Only center once
        if !windowWasAlreadyShownOnce {
            window?.center()
            windowWasAlreadyShownOnce = true
        }
        super.showWindow(sender)
        window?.makeFirstResponder(nil)
    }

    private static func makeSettingsTabViewItem(title: String,
                                                symbol: String,
                                                viewController: NSViewController) -> NSTabViewItem {
        viewController.title = title
        return NSTabViewItem(viewController: viewController).then {
            $0.label = title
            $0.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        }
    }
}
