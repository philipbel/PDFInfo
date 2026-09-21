import SwiftUI
import UniformTypeIdentifiers


nonisolated struct PDFDocumentModel: Sendable {
    let url: URL
    let fonts: [PDFFont]
    let version: String
    let pageCount: Int
    let pageSize: PDFPageSize?
    let metadata: [String: String]

    init(url: URL,
         fonts: [PDFFont] = [],
         version: String = "1.0",
         pageCount: Int = 0,
         pageSize: PDFPageSize? = nil,
         metadata: [String: String] = [:]) {
        self.url = url
        self.fonts = fonts
        self.version = version
        self.pageCount = pageCount
        self.pageSize = pageSize
        self.metadata = metadata
    }

    init(url: URL, data: Data) throws {
        guard let provider = CGDataProvider(data: data as CFData),
              let pdf = CGPDFDocument(provider) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.url = url
        self.fonts = Self.fonts(from: pdf)
        self.version = Self.version(of: pdf)
        self.pageCount = Self.pageCount(of: pdf)
        self.pageSize = Self.pageSize(of: pdf)
        self.metadata = Self.metadata(of: pdf)
    }

    private static func fonts(from pdf: CGPDFDocument) -> [PDFFont] {
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

    private static func version(of pdf: CGPDFDocument) -> String {
        var major: Int32 = 0, minor: Int32 = 0
        pdf.getVersion(majorVersion: &major, minorVersion: &minor)
        return "\(major).\(minor)"
    }

    private static func pageCount(of pdf: CGPDFDocument) -> Int {
        return pdf.numberOfPages
    }

    private static func pageSize(of pdf: CGPDFDocument) -> PDFPageSize? {
        guard let page = pdf.page(at: 1) else { return nil }

        let box = page.getBoxRect(.mediaBox) // points (1/72")
        return PDFPageSize(
            width: Measurement(value: Double(box.width) / 72, unit: .inches),
            height: Measurement(value: Double(box.height) / 72, unit: .inches)
        )
    }

    private static func infoString(_ dict: CGPDFDictionaryRef, _ key: String) -> String? {
        var ref: CGPDFStringRef?
        guard CGPDFDictionaryGetString(dict, key, &ref), let s = ref,
              let cf = CGPDFStringCopyTextString(s) else { return nil }
        return cf as String
    }

    private static func metadata(of pdf: CGPDFDocument) -> [String: String] {
        guard let info = pdf.info else { return [:] }
        var out: [String: String] = [:]
        for key in ["Title", "Author", "Subject", "Producer", "Creator", "Keywords"] {
            if let v = infoString(info, key) { out[key] = v }
        }
        return out
    }
}
