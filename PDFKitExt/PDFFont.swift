private import Foundation
internal import CoreGraphics
private import OSLog


fileprivate let logger = Logger(subsystem: "PDFKitExt", category: String(describing: "PDFFont"))


public protocol PDFFont: Identifiable {
    var baseFont: String { get }
    var subtype: PDFFontSubtype { get }
    var isSubset: Bool { get }
    var displayName: String { get }
    var isEmbedded: Bool { get }
}


extension PDFFont  {
    public var id: String {
        return "\(baseFont)-\(subtype)-\(isSubset)-\(displayName)"
    }
}


extension PDFFont {
    internal static func parseCommon(fromFontDictionary fontDictionary: CGPDFDictionaryRef) throws
    -> (baseFont: String, subtype: PDFFontSubtype, isSubset: Bool, displayName: String) {
        // TODO: subtype is read twice, here and in from(fontDictionary:)
        let subtype = try PDFFontParser.getSubtype(from: fontDictionary)

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
        let (displayName, isSubset) = Self.stripSubsetPrefix(baseFont)

        return (baseFont: baseFont, subtype: subtype, isSubset: isSubset, displayName: displayName)
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
