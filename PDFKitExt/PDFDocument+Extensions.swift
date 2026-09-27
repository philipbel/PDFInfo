@_exported public import PDFKit
internal import ObjectiveC
private import OSLog


fileprivate nonisolated(unsafe) var pdfDocumentFontAssociatedKey: UInt8 = 0


public extension PDFDocument {
    private static let logger = Logger(subsystem: "PDFKitExt", category: "PDFDocument")

    var version: String {
        "\(majorVersion).\(minorVersion)"
    }

    var pageSize: PDFPageSize? {
        guard let page = page(at: 0),
              let pageRef = page.pageRef else {
            return nil
        }
        let box = pageRef.getBoxRect(.mediaBox) // in points (1/72")
        return PDFPageSize(
            width: Measurement(value: Double(box.width) / 72, unit: .inches),
            height: Measurement(value: Double(box.height) / 72, unit: .inches)
        )
    }

    var metadata: PDFDocumentMetadata {
        let title = documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        let author = documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
        let subject = documentAttributes?[PDFDocumentAttribute.subjectAttribute] as? String
        let producer = documentAttributes?[PDFDocumentAttribute.producerAttribute] as? String
        let creator = documentAttributes?[PDFDocumentAttribute.creatorAttribute] as? String
        let keywords = documentAttributes?[PDFDocumentAttribute.keywordsAttribute] as? [String] ?? []
        let creationDate = documentAttributes?[PDFDocumentAttribute.creationDateAttribute] as? Date
        let modDate = documentAttributes?[PDFDocumentAttribute.modificationDateAttribute] as? Date

        return PDFDocumentMetadata(title: title,
                                   subject: subject,
                                   author: author,
                                   keywords: keywords,
                                   creator: creator,
                                   producer: producer,
                                   creationDate: creationDate,
                                   modificationDate: modDate)
    }

    var fonts: [any PDFFont] {
        get {
            if let fonts = objc_getAssociatedObject(self, &pdfDocumentFontAssociatedKey) as? [any PDFFont] {
                return fonts
            }
            let collectedFonts = readFonts()
            Self.logger.debug("fonts: Read \(collectedFonts.count) font(s)")

            objc_setAssociatedObject(self,
                                     &pdfDocumentFontAssociatedKey,
                                     collectedFonts as [any PDFFont]?,
                                     .OBJC_ASSOCIATION_RETAIN)
            return collectedFonts
        }
    }

    private func readFonts() -> [any PDFFont] {
        var fontMap: [String: any PDFFont] = [:]
        for i in 0..<pageCount {
            guard let page = page(at: i),
                  let pageRef = page.pageRef,
                  let pageDictionary = pageRef.dictionary,
                  let resourcesDictionary = pageDictionary.dictionary(forKey: "Resources"),
                  let fontDictionary = resourcesDictionary.dictionary(forKey: "Font") else {
                continue
            }
            Self.collectFonts(fromFontDictionary: fontDictionary, into: &fontMap)
        }
        return Array(fontMap.values)
    }

    private static func collectFonts(
        fromFontDictionary fontDictionary: CGPDFDictionaryRef,
        into fontMap: inout [String: any PDFFont]
    ) {
        fontDictionary.forEach { key, object in
            guard let dictionary = try? object.asDictionary(),
                  let pdfFont = try? PDFFontParser.fontFrom(fontDictionary: dictionary) else {
                return
            }
            fontMap[pdfFont.id] = pdfFont
        }
    }
}
