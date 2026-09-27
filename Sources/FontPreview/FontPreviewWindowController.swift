import Cocoa
import SwiftUI
import PDFKitExt


@MainActor
final class FontPreviewWindowController: NSWindowController {
    private lazy var previewViewController: NSHostingController = {
        let previewViewController = NSHostingController(rootView: AnyView(EmptyView()))
        previewViewController.sizingOptions = .preferredContentSize
        return previewViewController
    }()

    convenience init() {
        let panel = NSPanel()
        panel.styleMask = [.titled, .closable, .utilityWindow]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.title = "Font Preview"

        self.init(window: panel)
        panel.contentViewController = previewViewController
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    func update(font: any PDFFont) {
        previewViewController.rootView = AnyView(FontPreviewView(font: font, showDetails: true))
    }

    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        String(localized: "\(displayName)—Font Preview")
    }
}
