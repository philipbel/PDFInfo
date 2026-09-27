import Cocoa
import SwiftUI
import PDFKitExt


@MainActor
class Document: NSDocument {
    nonisolated(unsafe) var pdfDocument: PDFDocument?

    override func data(ofType typeName: String) throws -> Data {
        throw CocoaError(.fileWriteNoPermission)
    }

    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        pdfDocument = PDFDocument(url: url)
        guard pdfDocument != nil else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    override var isDocumentEdited: Bool { false }

    nonisolated override class var autosavesInPlace: Bool {
        return false
    }

    override func makeWindowControllers() {
        let documentWindowController = PDFDocumentWindowController()
        addWindowController(documentWindowController)
    }
}
