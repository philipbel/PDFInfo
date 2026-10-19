// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

public import Foundation
internal import PDFEngineCore


public struct PDFMetadata: Sendable {
    public let title: String?
    public let author: String?
    public let subject: String?
    public let keywords: [String]
    public let creator: String?
    public let producer: String?
    public let creationDate: Date?
    public let modDate: Date?
    public let trapped: Bool?

    init(metadata: OpaquePointer) {
        title = pdf_document_metadata_get_title(metadata).flatMap { String(validatingCString: $0) }
        author = pdf_document_metadata_get_author(metadata).flatMap { String(validatingCString: $0) }
        subject = pdf_document_metadata_get_subject(metadata).flatMap { String(validatingCString: $0) }
        keywords = (0..<pdf_document_metadata_get_keyword_count(metadata)).compactMap {
            pdf_document_metadata_get_keyword(metadata, $0)
        }.compactMap {
            String(validatingCString: $0)
        }
        creator = pdf_document_metadata_get_creator(metadata).flatMap { String(validatingCString: $0) }
        producer = pdf_document_metadata_get_producer(metadata).flatMap { String(validatingCString: $0) }
        creationDate = pdf_document_metadata_get_creation_date(metadata).map {
            Date(timeIntervalSince1970: TimeInterval($0.pointee))
        }
        modDate = pdf_document_metadata_get_mod_date(metadata).map {
            Date(timeIntervalSince1970: TimeInterval($0.pointee))
        }
        trapped = pdf_document_metadata_get_trapped(metadata).map { $0.pointee }
    }
}
