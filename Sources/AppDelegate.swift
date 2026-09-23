import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        /*
         * Load the menu here. See https://developer.apple.com/forums/thread/776832
         */
        var topLevel: NSArray? = nil
        Bundle.main.loadNibNamed("MainMenu", owner: NSApp, topLevelObjects: &topLevel)
    }

    func applicationDidFinishLaunching(_ note: Notification) {
        UserDefaults.standard.register(defaults: [
            Settings.previewText.key: Settings.previewText.default,
            Settings.previewFontSize.key: Settings.previewFontSize.default
        ])
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
        SettingsWindowController.shared.show()
    }
}
