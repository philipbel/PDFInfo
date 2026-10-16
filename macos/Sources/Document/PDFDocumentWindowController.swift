import Cocoa
import SwiftUI
import UniformTypeIdentifiers
import OSLog
import SettingsKit
import PDFEngine


fileprivate extension NSToolbarItem.Identifier {
    static let documentInspector = NSToolbarItem.Identifier("documentInspector")
    static let inspectorSeparator = NSToolbarItem.Identifier("inspectorSeparator")
}


fileprivate extension UserDefaults {
    static let inspectorVisible = Setting(key: "inspectorVisible", default: true)
}


final class PDFDocumentWindowController: NSWindowController {
    private static let windowFrameSaveKey: NSWindow.FrameAutosaveName = "PDFDocumentWindow"
    private static let minimumWindowSize = NSSize(width: 600, height: 400)
    private static let defaultWindowSize = NSSize(width: 800, height: 600)

    private static let logger = Logger(subsystem: "PDFInfo", category: "PDFDocumentWindowController")

    private lazy var splitViewController: NSSplitViewController = {
        let splitViewController = NSSplitViewController()
        splitViewController.addSplitViewItem(NSSplitViewItem(viewController: tableViewController))
        splitViewController.addSplitViewItem(inspectorSplitViewItem)
        return splitViewController
    }()
    private let documentInspectorViewController = NSHostingController(rootView: AnyView(EmptyView()))
    private lazy var tableViewController: FontTableViewController = {
        let tableViewController = FontTableViewController()
        tableViewController.onDoubleClick = { [weak self] font in
            self?.previewFont(font)
        }
        return tableViewController
    }()
    private lazy var inspectorSplitViewItem: NSSplitViewItem = {
        let inspectorSplitViewItem = NSSplitViewItem(inspectorWithViewController: documentInspectorViewController)
        inspectorSplitViewItem.canCollapse = true
        inspectorSplitViewItem.isCollapsed = false
        inspectorSplitViewItem.minimumThickness = 250
        inspectorSplitViewItem.maximumThickness = 500
        return inspectorSplitViewItem
    }()
    private lazy var documentInspectorToolbarItem: NSToolbarItem = {
        let i = NSToolbarItem(itemIdentifier: .documentInspector)
        i.label = String(localized: "Document Inspector")
        i.view = documentInspectorButton
        return i
    }()
    private lazy var documentInspectorButton: NSButton = {
        let b = NSButton(title: "",
                         target: self,
                         action: #selector(toggleInspector(_:)))
        b.image = NSImage(systemSymbolName: "sidebar.trailing",
                          accessibilityDescription: String(localized: "Document Inspector"))
        b.setButtonType(.pushOnPushOff)
        b.bezelStyle = .toolbar
        return b
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

        restoreInspectorVisibleState()
        inspectorCollapseObservation = inspectorSplitViewItem.observe(\.isCollapsed,
                                                                       options: [.initial, .new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateInspectorState()
            }
        }

        window.delegate = self
        self.window = window
    }

    func update() {
        guard let window else {
            Self.logger.warning("update(): no window")
            return
        }
        guard let document = document as? Document else {
            return
        }
        guard let url = document.fileURL,
            let pdfDocument else {
            Self.logger.error("update(): no document, url or PDFDocument")
            presentError(
                CocoaError(.fileReadCorruptFile),
                modalFor: window,
                delegate: nil,
                didPresent: nil,
                contextInfo: nil
            )
            return
        }
        Self.logger.debug("update(): updating from \(url)")
        updateInspectorTooltips()
        documentInspectorViewController.rootView = AnyView(DocumentInspectorView(document: pdfDocument, url: url))
        tableViewController.update(fonts: pdfDocument.fonts)
    }

    private func previewFont(_ font: PDFFont) {
        fontPreviewWindowController.configure(font: font)
        fontPreviewWindowController.showWindow(self)
    }

    override func showWindow(_ sender: Any?) {
        placeWindow()
        super.showWindow(sender)
    }

    private func placeWindow() {
        guard let window,
              !window.isVisible else {
            return
        }

        let topWindow = NSApplication.shared.orderedWindows.first {
            $0.isVisible && $0 != window && $0.windowController is PDFDocumentWindowController
        }

        // 1. Restore the saved window frame, if any
        let frameRestored = window.setFrameUsingName(Self.windowFrameSaveKey)

        if let topWindow {
            // 2a) Place the window cascaded off the last window
            let topLeft = window.cascadeTopLeft(from: CGPoint(x: topWindow.frame.minX, y: topWindow.frame.maxY))
            _ = window.cascadeTopLeft(from: topLeft)
        } else if !frameRestored {
            // 2b) First window, no previously saved frame => center
            window.center()
        }
        // 3. Save the frame for future windows
        window.saveFrame(usingName: Self.windowFrameSaveKey)
    }
}


// MARK: Delegate

extension PDFDocumentWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        windowDocument?.close()
        fontPreviewWindowController.close()
        window?.saveFrame(usingName: Self.windowFrameSaveKey)
    }

    func windowDidResize(_ notification: Notification) {
        window?.saveFrame(usingName: Self.windowFrameSaveKey)
    }
}


// MARK: Inspector

/// Note: we're not observing the `UserDefaults`'s `inspectorVisibleKey` so that hiding/showing the inspector in one
/// window doesn't immediately affect the inspector's state in other windows. Rather, only new document windows will be
/// affected.
extension PDFDocumentWindowController {
    @objc
    private func toggleInspector(_ sender: Any?) {
        inspectorSplitViewItem.animator().isCollapsed.toggle()
    }

    private func restoreInspectorVisibleState() {
        inspectorSplitViewItem.isCollapsed = !UserDefaults.standard[\.inspectorVisible]
    }

    private func persistInspectorVisibleState() {
        UserDefaults.standard[\.inspectorVisible] = !inspectorSplitViewItem.isCollapsed
    }

    private func updateInspectorState() {
        documentInspectorButton.state = inspectorSplitViewItem.isCollapsed ? .off : .on
        updateInspectorTooltips()
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
        case .documentInspector:
            return documentInspectorToolbarItem
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
        [.flexibleSpace, .inspectorSeparator, .flexibleSpace, .documentInspector]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.documentInspector, .inspectorSeparator, .flexibleSpace, .space]
    }

    private func updateInspectorTooltips() {
        if inspectorSplitViewItem.isCollapsed {
            documentInspectorToolbarItem.toolTip = String(localized: "Show the document inspector")
        } else {
            documentInspectorToolbarItem.toolTip = String(localized: "Hide the document inspector")
        }
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
