import AppKit
import Sparkle


final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updateController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil,
    )
    private var settingsWindowController: SettingsWindowController!
    private var topLevelObjects: NSArray? = nil

    func applicationWillFinishLaunching(_ notification: Notification) {
        /*
         * Load the menu here. See https://developer.apple.com/forums/thread/776832
         */
        Bundle.main.loadNibNamed("MainMenu", owner: NSApp, topLevelObjects: &topLevelObjects)
    }

    func applicationDidFinishLaunching(_ note: Notification) {
        settingsWindowController = SettingsWindowController(updateController: updateController)
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        let hasOpenPanel = NSApp.windows.contains { $0 is NSOpenPanel }
        if !hasOpenPanel {
            NSDocumentController.shared.openDocument(nil)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        false
    }

    @objc
    func openWebsite(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "https://philipbel.github.io/PDFInfo")!)
    }

    @objc
    func openIssueReport(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "https://github.com/philipbel/PDFInfo/issues/new")!)
    }

    @objc
    func showSettings(_ sender: Any?) {
        settingsWindowController.showWindow(sender)
    }

    @objc
    func checkForUpdates(_ sender: Any?) {
        updateController.checkForUpdates(sender)
    }
}
