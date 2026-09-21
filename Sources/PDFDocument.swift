import Cocoa
import SwiftUI


@MainActor
class PDFDocument: NSDocument {
    nonisolated(unsafe) var model: PDFDocumentModel?

    override func data(ofType typeName: String) throws -> Data {
        throw CocoaError(.fileWriteNoPermission)
    }

    override nonisolated func read(from url: URL, ofType typeName: String) throws {
        let data = try Data(contentsOf: url)
        model = try PDFDocumentModel(url: url, data: data)
    }

    override var isDocumentEdited: Bool { false }

    nonisolated override class var autosavesInPlace: Bool {
        return false
    }

    override func makeWindowControllers() {
        // By the time this runs, read(from:) has completed, so model is set
        if let model {
            addWindowController(PDFDocumentWindowController(model: model))
        }
    }
}
