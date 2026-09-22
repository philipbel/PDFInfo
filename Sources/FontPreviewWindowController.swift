import Cocoa
import SwiftUI


@MainActor
final class FontPreviewWindowController: NSWindowController {
    private var previewViewController: FontPreviewViewController!

    convenience init() {
        let previewViewController = FontPreviewViewController()
        let panel = NSPanel(contentViewController: previewViewController)
        panel.styleMask = [.titled, .closable, .utilityWindow]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.title = "Font Preview"

        self.init(window: panel)

        self.previewViewController = previewViewController
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    func show(font: PDFFont) {
        previewViewController.font = font
        showWindow(nil)
    }
}
