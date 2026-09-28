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
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path())
        lastModificationDate = attributes[.modificationDate] as? Date
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
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path()) else {
            Self.logger.warning("Cannot obtain attributes of \(fileURL)")
            return
        }
        guard let modificationDate = attributes[.modificationDate] as? Date,
            modificationDate != lastModificationDate else {
            return
        }
        lastModificationDate = modificationDate
        pdfDocument = PDFDocument(url: fileURL)
        DispatchQueue.main.async { [weak self] in
            self?.documentWindowController?.update()
        }
    }
}
