internal import Foundation
internal import CoreGraphics

public struct PDFType3Font: PDFProgramFont {
    public let descriptor: PDFFontDescriptor?
    public let baseFont: String
    public let subtype: PDFFontSubtype
    public let isSubset: Bool
    public let displayName: String
    public let id: String

    internal init(fromFontDictionary fontDictionary: CGPDFDictionaryRef, key: String) throws {
        (baseFont, subtype, isSubset, displayName) = try Self.parseCommon(fromFontDictionary: fontDictionary, key: key)
        descriptor = try Self.parseFontDescriptor(fromFontDictionary: fontDictionary)
        // Type3 fonts have an optional name and thus possibly no ID, so use the font dictionary as identifier
        id = "\(key)-\(UInt(bitPattern: fontDictionary.rawValue))"
        try validateSubtype(expected: [.type3])
    }
}
