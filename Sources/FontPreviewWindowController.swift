import Cocoa
import SwiftUI


@MainActor
final class FontPreviewWindowController: NSWindowController {
    private var viewModel: FontPreviewViewModel!

    convenience init() {
        let viewModel = FontPreviewViewModel()

        let hostingViewController = NSHostingController(rootView: FontPreviewView(viewModel: viewModel))
        hostingViewController.sizingOptions = [.preferredContentSize]
        let panel = NSPanel(contentViewController: hostingViewController)
        panel.styleMask = [.titled, .closable, .utilityWindow]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.title = "Font Preview"

        self.init(window: panel)
        self.viewModel = viewModel
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    func show(font: PDFFont) {
        viewModel.font = font
        showWindow(nil)
    }
}
