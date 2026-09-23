import SwiftUI
import UniformTypeIdentifiers
import PDFKit


nonisolated struct PDFDocumentModel: Sendable {
    struct Metadata: Sendable, Equatable {
        let title: String?
        let subject: String?
        let author: String?
        let keywords: [String]
        let creator: String?
        let producer: String?
        let creationDate: Date?
        let modificationDate: Date?

        init(
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

    let url: URL
    let fonts: [PDFFont]
    let version: String
    let pageCount: Int
    let pageSize: PDFPageSize?
    let metadata: Metadata

    init(url: URL,
         fonts: [PDFFont] = [],
         version: String = "1.0",
         pageCount: Int = 0,
         pageSize: PDFPageSize? = nil,
         metadata: Metadata = Metadata()) {
        self.url = url
        self.fonts = fonts
        self.version = version
        self.pageCount = pageCount
        self.pageSize = pageSize
        self.metadata = metadata
    }

    init(url: URL) throws {
        guard let pdfDocument = PDFKit.PDFDocument(url: url) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.init(url: url, pdfDocument: pdfDocument)
    }

    init(url: URL, data: Data) throws {
        guard let pdfDocument = PDFKit.PDFDocument(data: data) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.init(url: url, pdfDocument: pdfDocument)
    }

    private init(url: URL, pdfDocument: PDFKit.PDFDocument) {
        self.url = url
        self.fonts = Self.fonts(from: pdfDocument)
        self.version = Self.version(of: pdfDocument)
        self.pageCount = Self.pageCount(of: pdfDocument)
        self.pageSize = Self.pageSize(of: pdfDocument)
        self.metadata = Self.metadata(from: pdfDocument)
    }

    private static func fonts(from pdfDocument: PDFKit.PDFDocument) -> [PDFFont] {
        guard let pdf = pdfDocument.documentRef else {
            return []
        }

        var found = Set<PDFFont>()
        
        for i in 1...max(pdf.numberOfPages, 1) {
            guard let page = pdf.page(at: i),
                  let dict = page.dictionary else { continue }
            var resources: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(dict, "Resources", &resources),
                  let res = resources else { continue }
            collectFonts(from: res, into: &found)
        }
        return Array(found)
    }
    
    private static func collectFonts(from resources: CGPDFDictionaryRef,
                                     into found: inout Set<PDFFont>) {
        var fontDict: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "Font", &fontDict),
              let fonts = fontDict else { return }

        // ApplyBlock iterates each entry; key is a C string, value is generic CGPDFObjectRef
        CGPDFDictionaryApplyBlock(fonts, { _, value, _ in
            var font: CGPDFDictionaryRef?
            guard CGPDFObjectGetValue(value, .dictionary, &font),
                  let f = font else { return true }

            found.insert(parseFont(f))
            return true   // return true to continue iteration
        }, nil)
    }

    private static func isFontEmbedded(_ descriptor: CGPDFDictionaryRef) -> Bool {
        var stream: CGPDFStreamRef?
        return CGPDFDictionaryGetStream(descriptor, "FontFile", &stream)
            || CGPDFDictionaryGetStream(descriptor, "FontFile2", &stream)
            || CGPDFDictionaryGetStream(descriptor, "FontFile3", &stream)
    }

    private static func resolveFont(_ font: CGPDFDictionaryRef, subtype: String)
        -> (descriptor: CGPDFDictionaryRef?, subtype: String) {
        guard subtype == "Type0" else {
            // Simple fonts: descriptor on the font dict, subtype as-is
            var descriptor: CGPDFDictionaryRef?
            let desc = CGPDFDictionaryGetDictionary(font, "FontDescriptor", &descriptor)
                ? descriptor : nil
            return (desc, subtype)
        }

        // Type0: descend into the CIDFont for both descriptor and real subtype
        var descendants: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(font, "DescendantFonts", &descendants),
              let arr = descendants,
              CGPDFArrayGetCount(arr) > 0 else {
            return (nil, subtype)
        }

        var cidFont: CGPDFDictionaryRef?
        guard CGPDFArrayGetDictionary(arr, 0, &cidFont),
              let cid = cidFont else {
            return (nil, subtype)
        }

        var cidSubName: UnsafePointer<CChar>?
        let cidSubtype = CGPDFDictionaryGetName(cid, "Subtype", &cidSubName)
            ? (cidSubName.map { String(cString: $0) } ?? subtype)
            : subtype

        var descriptor: CGPDFDictionaryRef?
        let desc = CGPDFDictionaryGetDictionary(cid, "FontDescriptor", &descriptor)
            ? descriptor : nil

        return (desc, cidSubtype)
    }

    private static func parseFont(_ font: CGPDFDictionaryRef) -> PDFFont {
        var baseName: UnsafePointer<CChar>?
        CGPDFDictionaryGetName(font, "BaseFont", &baseName)
        let base = baseName.map { String(cString: $0) } ?? "(unknown)"

        var subName: UnsafePointer<CChar>?
        CGPDFDictionaryGetName(font, "Subtype", &subName)
        let rawSubtype = subName.map { String(cString: $0) } ?? "(unknown)"
        let (fontDescriptor, subtype) = Self.resolveFont(font, subtype: rawSubtype)
        let isEmbedded = fontDescriptor.map(Self.isFontEmbedded) ?? false
        let (name, subset) = stripSubsetPrefix(base)

        return PDFFont(
            id: "\(UInt(bitPattern: font.rawValue))",
            name: name,
            subtype: subtype,
            embedded: isEmbedded,
            subset: subset
        )
    }
    
    private static func stripSubsetPrefix(_ name: String) -> (display: String, isSubset: Bool) {
        let pattern = #"^[A-Z]{6}\+"#
        if let range = name.range(of: pattern, options: .regularExpression) {
            return (String(name[range.upperBound...]), true)
        }
        return (name, false)
    }

    private static func version(of pdfDocument: PDFKit.PDFDocument) -> String {
        return "\(pdfDocument.majorVersion).\(pdfDocument.minorVersion)"
    }

    private static func pageCount(of pdfDocument: PDFKit.PDFDocument) -> Int {
        return pdfDocument.pageCount
    }

    private static func pageSize(of pdfDocument: PDFKit.PDFDocument) -> PDFPageSize? {
        guard let pdf = pdfDocument.documentRef,
              let page = pdf.page(at: 1) else {
            return nil
        }
        let box = page.getBoxRect(.mediaBox) // in points (1/72")
        return PDFPageSize(
            width: Measurement(value: Double(box.width) / 72, unit: .inches),
            height: Measurement(value: Double(box.height) / 72, unit: .inches)
        )
    }

    private static func metadata(from pdfDocument: PDFKit.PDFDocument) -> Metadata {
        let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        let author = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
        let subject = pdfDocument.documentAttributes?[PDFDocumentAttribute.subjectAttribute] as? String
        let producer = pdfDocument.documentAttributes?[PDFDocumentAttribute.producerAttribute] as? String
        let creator = pdfDocument.documentAttributes?[PDFDocumentAttribute.creatorAttribute] as? String
        let keywords = pdfDocument.documentAttributes?[PDFDocumentAttribute.keywordsAttribute] as? [String] ?? []
        let creationDate = pdfDocument.documentAttributes?[PDFDocumentAttribute.creationDateAttribute] as? Date
        let modDate = pdfDocument.documentAttributes?[PDFDocumentAttribute.modificationDateAttribute] as? Date

        return Metadata(title: title,
                        subject: subject,
                        author: author,
                        keywords: keywords,
                        creator: creator,
                        producer: producer,
                        creationDate: creationDate,
                        modificationDate: modDate)
    }
}
