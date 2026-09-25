internal import Foundation
public import CoreGraphics
internal import OSLog


fileprivate let logger = Logger(subsystem: "PDFKitExt", category: String(describing: PDFBaseFont.self))


public class PDFBaseFont: Hashable, CustomDebugStringConvertible {
    public var baseFont: String
    public var subtype: PDFFontSubtype
    public var isSubset: Bool
    public var displayName: String

    public var debugDescription: String {
        "PDFBaseFont("
        + "baseFont: \"\(baseFont)\""
        + ", subtype: \"\(subtype)\""
        + ", isSubset: \(isSubset)"
        + ", displayName: \"\(displayName)\""
        + ")"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(baseFont)
        hasher.combine(subtype)
    }

    public static func == (lhs: borrowing PDFBaseFont, rhs: borrowing PDFBaseFont) -> Bool {
        lhs.baseFont == rhs.baseFont && lhs.subtype == rhs.subtype
    }

    internal init(from fontDictionary: CGPDFDictionaryRef) throws {
        // TODO: subtype is read twice, here and in from(fontDictionary:)
        subtype = try Self.getSubtype(from: fontDictionary)

        guard let type = fontDictionary.name(forKey: "Type") else {
            let err = PDFKitError.corruptedObject(message: "No 'Type'")
            logger.error("init(): error: \(err)")
            throw err
        }
        guard type == "Font" else {
            let err = PDFKitError.corruptedObject(message: "Invalid font type '\(type)'")
            logger.error("init(): error: \(err)")
            throw err
        }
        guard let baseFont = fontDictionary.name(forKey: "BaseFont") else {
            let err = PDFKitError.corruptedObject(message: "No 'BaseFont'")
            logger.error("init(): error: \(err)")
            throw err
        }
        self.baseFont = baseFont
        (self.displayName, self.isSubset) = Self.stripSubsetPrefix(self.baseFont)
    }

    public static func from(fontDictionary: CGPDFDictionaryRef) throws -> PDFBaseFont? {
        let subtype: PDFFontSubtype
        do {
            subtype = try Self.getSubtype(from: fontDictionary)
        } catch {
            logger.error("Error getting font subtype: \(error)")
            throw error
        }
        logger.debug("from(): creating font for subtype \(subtype)")
        switch subtype {
        case .type0: return try PDFType0Font(from: fontDictionary)
        case .type1, .mmType1: return try PDFType1Font(from: fontDictionary)
        case .type3: return try PDFType3Font(from: fontDictionary)
        case .trueType: return try PDFTrueTypeFont(from: fontDictionary)
        case .cidFontType0, .cidFontType2: return try PDFCIDFont(from: fontDictionary)
        }
    }

    private static func getSubtype(from fontDictionary: CGPDFDictionaryRef) throws -> PDFFontSubtype {
        guard let subtype = fontDictionary.name(forKey: "Subtype") else {
            let msg = "No 'Subtype'"
            logger.error("getSubtype(): \(msg))")
            throw PDFKitError.corruptedObject(message: msg)
        }
        switch subtype {
        case "Type0": return .type0
        case "Type1":
            return .type1
        case "MMType1":
            return .mmType1
        case "Type3": return .type3
        case "TrueType": return .trueType
        case "CIDFontType0": return .cidFontType0
        case "CIDFontType2": return .cidFontType2
        default:
            let msg = "Invalid 'Subtype' '\(subtype)'"
            logger.error("getSubtype(): \(msg)")
            throw PDFKitError.corruptedObject(message: msg)
        }
    }

    internal func validateSubtype(expected: [PDFFontSubtype]) throws {
        guard expected.contains(subtype) else {
            let err = PDFKitError.makeInvalidFontTypeError(expected: expected, actual: subtype)
            logger.error("validateSubtype(): validation error: \(err)")
            throw err
        }
    }

    private static func stripSubsetPrefix(_ name: String) -> (display: String, isSubset: Bool) {
        let pattern = #"^[A-Z]{6}\+"#
        if let range = name.range(of: pattern, options: .regularExpression) {
            return (String(name[range.upperBound...]), true)
        }
        return (name, false)
    }
}
