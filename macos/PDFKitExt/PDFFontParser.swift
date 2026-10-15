public import CoreGraphics
private import OSLog


public struct PDFFontParser {
    private static let logger = Logger(subsystem: "PDFKitExt", category: "PDFFontParser")

    public static func fontFrom(fontDictionary: CGPDFDictionaryRef, key: String) throws -> any PDFFont {
        let subtype: PDFFontSubtype
        do {
            subtype = try Self.getSubtype(from: fontDictionary)
        } catch {
            logger.error("Error getting font subtype: \(error)")
            throw error
        }
        logger.debug("from(): creating font for subtype \(subtype)")
        switch subtype {
        case .type0: return try PDFType0Font(fromFontDictionary: fontDictionary, key: key)
        case .type1, .mmType1: return try PDFType1Font(fromFontDictionary: fontDictionary, key: key)
        case .type3: return try PDFType3Font(fromFontDictionary: fontDictionary, key: key)
        case .trueType: return try PDFTrueTypeFont(fromFontDictionary: fontDictionary, key: key)
        case .cidFontType0, .cidFontType2: return try PDFCIDFont(fromFontDictionary: fontDictionary, key: key)
        }
    }

    internal static func getSubtype(from fontDictionary: CGPDFDictionaryRef) throws -> PDFFontSubtype {
        guard let subtype = fontDictionary.name(forKey: "Subtype") else {
            let msg = "No 'Subtype'"
            logger.error("getSubtype(): \(msg)")
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
}
