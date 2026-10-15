import Cocoa
import PDFKitExt


final class FontPreviewWindowController: NSWindowController {
    private let previewViewController = FontPreviewViewController()
    private var alreadyShown = false

    convenience init() {
        let panel = NSPanel()
        panel.styleMask = [.titled, .closable, .utilityWindow]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.title = String(localized: "Font Preview")

        self.init(window: panel)
        panel.contentViewController = previewViewController
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    override func showWindow(_ sender: Any?) {
        if let window, !alreadyShown {
            window.contentView?.layoutSubtreeIfNeeded()
            window.setContentSize(previewViewController.view.fittingSize)
            window.center()
            alreadyShown = true
        }
        super.showWindow(sender)
    }

    func configure(font pdfFont: any PDFFont) {
        previewViewController.configure(font: pdfFont)
    }
}
