import Cocoa
import SwiftUI
import PDFKitExt


fileprivate struct FontPreviewWrapperView: View {
    let pdfFont: any PDFFont?

    var body: some View {
        if let pdfFont {
            FontPreviewView(font: pdfFont, showDetails: true)
                .id(pdfFont.id)
        } else {
            ContentUnavailableView("No font selected", systemImage: "textformat")
        }
    }
}


final class FontPreviewWindowController: NSWindowController {
    private lazy var previewViewController: NSHostingController = {
        let previewViewController = NSHostingController(rootView: FontPreviewWrapperView(pdfFont: nil))
        previewViewController.sizingOptions = .preferredContentSize
        return previewViewController
    }()
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

    func update(font pdfFont: any PDFFont) {
        previewViewController.rootView = FontPreviewWrapperView(pdfFont: pdfFont)
    }
}
