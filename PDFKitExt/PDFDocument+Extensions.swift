public import PDFKit
internal import ObjectiveC
private import OSLog


fileprivate nonisolated(unsafe) var pdfDocumentFontAssociatedKey: UInt8 = 0


public extension PDFDocument {
    private static let logger = Logger(subsystem: "PDFKitExt", category: "PDFDocument")

    var fonts: Set<PDFBaseFont> {
        get {
            if let fonts = objc_getAssociatedObject(self, &pdfDocumentFontAssociatedKey) as? Set<PDFBaseFont> {
                return fonts
            }
            let collectedFonts = readFonts()
            Self.logger.debug("fonts: Read \(collectedFonts.count) font(s)")

            objc_setAssociatedObject(self,
                                     &pdfDocumentFontAssociatedKey,
                                     collectedFonts as Set<PDFBaseFont>?,
                                     .OBJC_ASSOCIATION_RETAIN)
            return collectedFonts
        }
    }

    private func readFonts() -> Set<PDFBaseFont> {
        // TODO: Put in a set?
        var found: Set<PDFBaseFont> = []
        for i in 0..<pageCount {
            guard let page = page(at: i),
                  let pageRef = page.pageRef,
                  let pageDictionary = pageRef.dictionary,
                  let resourcesDictionary = pageDictionary.dictionary(forKey: "Resources"),
                  let fontDictionary = resourcesDictionary.dictionary(forKey: "Font") else {
                continue
            }
            found.formUnion(Self.collectFonts(fromFontDictionary: fontDictionary))
//            found.formUnion(collectFonts(from: res))
        }
        return found
    }

    private static func collectFonts(fromFontDictionary fontDictionary: CGPDFDictionaryRef) -> Set<PDFBaseFont> {
        let fonts: [PDFBaseFont] = fontDictionary.compactMap { key, object in
            guard let dictionary = try? object.asDictionary(),
                  let pdfFont = try? PDFBaseFont.from(fontDictionary: dictionary) else {
                return nil
            }
            let objectPtr = UInt(bitPattern: object.rawValue)
            logger.debug("collectFonts(): Font objectPtr=\(String(format: "%02X", objectPtr))")
            return pdfFont
        }
        return Set(fonts)
    }
}
