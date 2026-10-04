import Cocoa
import SwiftUI
import PDFKitExt
import OSLog


@MainActor
class Document: NSDocument {
    nonisolated private static let logger = Logger(subsystem: "PDFInfo", category: "Document")
    nonisolated(unsafe) var pdfDocument: PDFDocument?
    private var documentWindowController: PDFDocumentWindowController?
    nonisolated(unsafe) private var lastModificationDate: Date?

    override func data(ofType typeName: String) throws -> Data {
        throw CocoaError(.fileWriteNoPermission)
    }

    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        pdfDocument = PDFDocument(url: url)
        guard pdfDocument != nil else {
            throw CocoaError(.fileReadCorruptFile)
        }
        lastModificationDate = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    override var isDocumentEdited: Bool { false }

    nonisolated override class var autosavesInPlace: Bool {
        return false
    }

    override func makeWindowControllers() {
        let documentWindowController = PDFDocumentWindowController()
        addWindowController(documentWindowController)
        self.documentWindowController = documentWindowController
    }
}


// NSFilePresenter
extension Document {
    override nonisolated func presentedItemDidChange() {
        super.presentedItemDidChange()
        guard let fileURL else {
            Self.logger.warning("presentedItemDidChange(): fileURL is nil")
            return
        }
        // Reload after a while to avoid a race with another writer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            let modificationDate = try? fileURL.resourceValues(
                forKeys: [.contentModificationDateKey]).contentModificationDate
            guard let modificationDate,
                  modificationDate != lastModificationDate else {
                return
            }
            lastModificationDate = modificationDate
            pdfDocument = PDFDocument(url: fileURL)
            documentWindowController?.update()
        }
    }
}
