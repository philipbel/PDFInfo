internal import Foundation
internal import CoreGraphics


public protocol PDFProgramFont: PDFFont {
    var descriptor: PDFFontDescriptor? { get }
}


extension PDFProgramFont {
    public var id: String {
        return "\(baseFont)-\(subtype)-\(isSubset)-\(displayName)-\(String(describing: descriptor?.id))"
    }

    public var isEmbedded: Bool {
        descriptor?.program != nil
    }

    internal static func parseFontDescriptor(fromFontDictionary fontDictionary: CGPDFDictionaryRef) throws
    -> PDFFontDescriptor? {
        if let fontDescriptorDict = fontDictionary.dictionary(forKey: "FontDescriptor") {
            return try PDFFontDescriptor(from: fontDescriptorDict)
        }
        return nil
    }
}
