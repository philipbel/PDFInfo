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

@MainActor
final class FontPreviewWindowController: NSWindowController {
    private static let autosaveName: NSWindow.FrameAutosaveName = "fontPreview"

    private lazy var previewViewController: NSHostingController = {
        let previewViewController = NSHostingController(rootView: FontPreviewWrapperView(pdfFont: nil))
        previewViewController.sizingOptions = .preferredContentSize
        return previewViewController
    }()

    convenience init() {
        let panel = NSPanel()
        panel.styleMask = [.titled, .closable, .utilityWindow]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.title = String(localized: "Font Preview")

        self.init(window: panel)
        panel.contentViewController = previewViewController
        panel.setFrameAutosaveName(Self.autosaveName)
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    func update(font pdfFont: any PDFFont) {
        previewViewController.rootView = FontPreviewWrapperView(pdfFont: pdfFont)
    }
}
