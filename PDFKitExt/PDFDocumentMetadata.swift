public import Foundation

public struct PDFDocumentMetadata: Sendable, Equatable {
    public let title: String?
    public let subject: String?
    public let author: String?
    public let keywords: [String]
    public let creator: String?
    public let producer: String?
    public let creationDate: Date?
    public let modificationDate: Date?

    public init(
        title: String? = nil,
        subject: String? = nil,
        author: String? = nil,
        keywords: [String] = [],
        creator: String? = nil,
        producer: String? = nil,
        creationDate: Date? = nil,
        modificationDate: Date? = nil,
    ) {
        self.title = title
        self.subject = subject
        self.author = author
        self.keywords = keywords
        self.creator = creator
        self.producer = producer
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
}
