// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

public import Foundation
private import PDFEngineCore


public struct PDFDocumentVersion: Sendable, CustomStringConvertible {
    public let major: UInt
    public let minor: UInt
    public let `extension`: UInt

    fileprivate init(version: pdf_document_version) {
        major = UInt(version.major)
        minor = UInt(version.minor)
        `extension` = UInt(version.extension)
    }

    public var description: String {
        if `extension` > 0 {
            "\(major).\(minor).\(`extension`)"
        } else {
            "\(major).\(minor)"
        }
    }
}


public enum PDFPaperSize: Sendable {
    case custom
    case a4
    case letter

    fileprivate init(paperSize: pdf_page_paper_size) {
        switch paperSize {
        case PDF_PAGE_PAPER_SIZE_CUSTOM:
            self = .custom
        case PDF_PAGE_PAPER_SIZE_A4:
            self = .a4
        case PDF_PAGE_PAPER_SIZE_LETTER:
            self = .letter
        default:
            fatalError("Unsupported paper size \(paperSize.rawValue)")
        }
    }
}


public enum PDFPageSizeOrientation: Sendable {
    case portrait
    case landscape

    fileprivate init(orientation: pdf_page_size_orientation) {
        switch orientation {
        case PDF_PAGE_SIZE_ORIENTATION_PORTRAIT:
            self = .portrait
        case PDF_PAGE_SIZE_ORIENTATION_LANDSCAPE:
            self = .landscape
        default:
            fatalError("Unsupported orientation \(orientation.rawValue)")
        }
    }
}


public struct PDFPageSize: Sendable {
    public let width: Measurement<UnitLength>
    public let height: Measurement<UnitLength>
    public let paperSize: PDFPaperSize
    public let orientation: PDFPageSizeOrientation

    fileprivate init(pageSize: pdf_page_size) {
        // Note: page sizes are in points, 1/72th of an inch
        width = Measurement(value: pageSize.width / 72, unit: .inches)
        height = Measurement(value: pageSize.height / 72, unit: .inches)
        paperSize = PDFPaperSize(paperSize: pageSize.paper_size)
        orientation = PDFPageSizeOrientation(orientation: pageSize.orientation)
    }
}


public struct PDFDocument: Sendable {
    public let metadata: PDFMetadata?
    public let version: PDFDocumentVersion
    public let pageCount: UInt
    public let fonts: [PDFFont]
    public let pageSize: PDFPageSize?

    public init?(data: Data) {
        guard let documentPtr = data.withUnsafeBytes({ raw in
            pdf_document_open(raw.bindMemory(to: UInt8.self).baseAddress, raw.count)
        }) else {
            return nil
        }
        defer {
            pdf_document_free(documentPtr)
        }

        metadata = pdf_document_get_metadata(documentPtr).map { PDFMetadata(metadata: $0) }
        version = PDFDocumentVersion(version: pdf_document_get_version(documentPtr))
        pageCount = UInt(pdf_document_get_page_count(documentPtr))
        fonts = (0..<pdf_document_get_font_count(documentPtr)).map {
            PDFFont(font: pdf_document_get_font(documentPtr, $0))
        }
        pageSize = pdf_document_get_page_size(documentPtr).map { PDFPageSize(pageSize: $0.pointee) }
    }
}
