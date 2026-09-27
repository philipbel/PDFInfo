import Cocoa
import SwiftUI
import UniformTypeIdentifiers
import PDFKitExt


private extension NSToolbarItem.Identifier {
    static let inspector = NSToolbarItem.Identifier("inspector")
    static let inspectorSeparator = NSToolbarItem.Identifier("inspectorSeparator")
}


final class PDFDocumentWindowController: NSWindowController {
    private static let windowFrameSaveKey: NSWindow.FrameAutosaveName = "PDFDocumentWindow"
    private static let inspectorVisibleKey = "inspectorVisible"
    private static let minimumWindowSize = NSSize(width: 600, height: 400)
    private static let defaultWindowSize = NSSize(width: 800, height: 600)

    private lazy var splitViewController: NSSplitViewController = {
        let splitViewController = NSSplitViewController()
        splitViewController.addSplitViewItem(NSSplitViewItem(viewController: tableViewController))
        splitViewController.addSplitViewItem(inspectorSplitViewItem)
        return splitViewController
    }()
    private let inspectorViewController = NSHostingController(rootView: AnyView(EmptyView()))
    private lazy var tableViewController: FontTableViewController = {
        let tableViewController = FontTableViewController()
        tableViewController.onDoubleClick = { [weak self] font in
            self?.previewFont(font)
        }
        return tableViewController
    }()
    private lazy var inspectorSplitViewItem: NSSplitViewItem = {
        let inspectorSplitViewItem = NSSplitViewItem(inspectorWithViewController: inspectorViewController)
        inspectorSplitViewItem.canCollapse = true
        inspectorSplitViewItem.minimumThickness = 250
        inspectorSplitViewItem.maximumThickness = 500
        return inspectorSplitViewItem
    }()
    private lazy var inspectorToolbarItem: NSToolbarItem = {
        let inspectorToolbarItem = NSToolbarItem(itemIdentifier: .inspector)
        inspectorToolbarItem.label = "Inspector"
        inspectorToolbarItem.view = inspectorButton
        return inspectorToolbarItem
    }()
    private lazy var inspectorButton: NSButton = {
        let inspectorButton = NSButton(image: NSImage(systemSymbolName: "info", accessibilityDescription: "Inspector")!,
                                   target: self,
                                   action: #selector(toggleInspector(_:)))
        inspectorButton.setButtonType(.pushOnPushOff)
        inspectorButton.bezelStyle = .toolbar
        return inspectorButton
    }()
    private let fontPreviewWindowController = FontPreviewWindowController()
    private var inspectorCollapseObservation: NSKeyValueObservation?

    override var document: AnyObject? {
        didSet {
            update()
        }
    }

    var windowDocument: Document? {
        document as? Document
    }

    var pdfDocument: PDFDocument? {
        windowDocument?.pdfDocument
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    convenience init() {
        self.init(window: nil)

        let window = NSWindow(contentViewController: splitViewController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.contentMinSize = Self.minimumWindowSize
        window.setContentSize(Self.defaultWindowSize)
        window.toolbarStyle = .unified
        window.toolbar = makeToolbar()

        let dragForwardView = DropOverlayView(frame: window.contentView!.bounds,
                                              draggedTypes: [.fileURL],
                                              destination: self,
                                              fileCount: { [weak self] sender in
            self?.pdfURLs(from: sender).count ?? 0
        })
        dragForwardView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(dragForwardView)

        inspectorCollapseObservation = inspectorSplitViewItem.observe(\.isCollapsed,
                                                                       options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateInspectorState()
            }
        }
        restoreInspectorVisibleState()
        updateInspectorState()

        window.delegate = self
        self.window = window
        // Do this last
        window.setFrameAutosaveName(Self.windowFrameSaveKey)
    }

    private func update() {
        guard let window else {
            return
        }
        guard let document = document as? Document,
            let url = document.fileURL,
            let pdfDocument else {
            window.contentViewController = nil
            return
        }
        adjustInspectorTooltip()
        inspectorViewController.rootView = AnyView(DocumentInspectorView(document: pdfDocument, url: url))
        tableViewController.update(fonts: pdfDocument.fonts)
    }

    private func previewFont(_ font: any PDFFont) {
        fontPreviewWindowController.update(font: font)
        fontPreviewWindowController.showWindow(self)
    }
}


// MARK: Delegate

extension PDFDocumentWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        windowDocument?.close()
        fontPreviewWindowController.close()
    }
}


// MARK: Inspector

extension PDFDocumentWindowController {
    @objc
    private func toggleInspector(_ sender: Any?) {
        inspectorSplitViewItem.animator().isCollapsed.toggle()
    }

    private func restoreInspectorVisibleState() {
        inspectorSplitViewItem.isCollapsed = !UserDefaults.standard.bool(forKey: Self.inspectorVisibleKey)
    }

    private func persistInspectorVisibleState() {
        UserDefaults.standard.set(!inspectorSplitViewItem.isCollapsed, forKey: Self.inspectorVisibleKey)
    }

    private func updateInspectorState() {
        inspectorButton.state = inspectorSplitViewItem.isCollapsed ? .off : .on
        adjustInspectorTooltip()
        persistInspectorVisibleState()
    }
}


// MARK: Toolbar

extension PDFDocumentWindowController {
    private func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "PDFDocumentToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        return toolbar
    }
}

extension PDFDocumentWindowController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch identifier {
        case .inspector:
            return inspectorToolbarItem
        case .inspectorSeparator:
            return NSTrackingSeparatorToolbarItem(
                identifier: .inspectorSeparator,
                splitView: splitViewController.splitView,
                dividerIndex: 0
            )
        default:
            return nil
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .inspectorSeparator, .flexibleSpace, .inspector]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.inspector,.inspectorSeparator, .flexibleSpace, .space]
    }

    private func adjustInspectorTooltip() {
        inspectorToolbarItem.toolTip = if inspectorSplitViewItem.isCollapsed {
            "Show the document inspector"
        } else {
            "Hide the document inspector"
        }
    }
}

extension PDFDocumentWindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return true
    }
}


// MARK: Drag and Drop

extension PDFDocumentWindowController: NSDraggingDestination {
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        pdfURLs(from: sender).isEmpty ? [] : .copy
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = pdfURLs(from: sender)
        for url in urls {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
        }
        return !urls.isEmpty
    }

    private func pdfURLs(from sender: NSDraggingInfo) -> [URL] {
        (sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true,
                      .urlReadingContentsConformToTypes: [UTType.pdf.identifier]]
        ) as? [URL]) ?? []
    }
}
