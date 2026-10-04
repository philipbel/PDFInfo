internal import Foundation
internal import CoreGraphics

public struct PDFTrueTypeFont: PDFProgramFont {
    public let descriptor: PDFFontDescriptor?
    public let baseFont: String
    public let subtype: PDFFontSubtype
    public let isSubset: Bool
    public let displayName: String

    internal init(fromFontDictionary fontDictionary: CGPDFDictionaryRef, key: String) throws {
        (baseFont, subtype, isSubset, displayName) = try Self.parseCommon(fromFontDictionary: fontDictionary, key: key)
        descriptor = try Self.parseFontDescriptor(fromFontDictionary: fontDictionary)
        try validateSubtype(expected: [.trueType])
    }
}
