internal import Foundation
internal import CoreGraphics
private import OSLog

fileprivate let logger = Logger(subsystem: "PDFKitExt", category: String(describing: PDFFontDescriptor.self))



public struct PDFFontDescriptor {
    public let name: String
    public let fontFamily: String?
    public var fontWeight: Int?
    public var flags: Int
    internal var program: PDFFontProgram?

    internal init(from fontDescriptorDictionary: CGPDFDictionaryRef) throws {
        let type = fontDescriptorDictionary.name(forKey: "Type")
        guard let type else {
            let msg = "'FontDescriptor' has not 'Type'"
            logger.error("init(): \(msg)")
            throw PDFKitError.corruptedObject(message: msg)
        }
        guard type == "FontDescriptor" else {
            let msg = "Expected 'Type' = 'FontDescriptor', got '\(type)'"
            logger.error("init(): \(msg)")
            throw PDFKitError.corruptedObject(message: msg)
        }
        guard let name = fontDescriptorDictionary.name(forKey: "FontName") else {
            let msg = "FontDescriptor has no 'FontName'"
            logger.error("init(): \(msg)")
            throw PDFKitError.corruptedObject(message: msg)
        }
        guard let flags = fontDescriptorDictionary.integer(forKey: "Flags") else {
            let msg = "FontDescriptor has no 'Flags'"
            logger.error("init(): \(msg)")
            throw PDFKitError.corruptedObject(message: msg)
        }
        self.fontFamily = fontDescriptorDictionary.string(forKey: "FontFamily")
        self.fontWeight = fontDescriptorDictionary.number(forKey: "FontWeight").map(Int.init)
        self.name = name
        self.flags = flags
        self.program = try PDFFontProgram(fromFontDescriptorDictionary: fontDescriptorDictionary)
    }
}


// MARK: CustomDebugStringConvertible

extension PDFFontDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "PDFFontDescriptor("
        + "name: \(name),"
        + ", fontFamily: \"\(fontFamily ?? "nil")\""
        + ", fontWeight: \(fontWeight?.description ?? "nil")"
        + ", flags: \(flags)"
        + ", program: \(program?.debugDescription ?? "nil")"
        + ")"
    }
}


// MARK: Hashable

extension PDFFontDescriptor: Hashable {
    public static func == (lhs: borrowing PDFFontDescriptor, rhs: borrowing PDFFontDescriptor) -> Bool {
        lhs.name == rhs.name &&
        lhs.fontFamily == rhs.fontFamily &&
        lhs.fontWeight == rhs.fontWeight &&
        lhs.flags == rhs.flags &&
        lhs.program == rhs.program
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(fontFamily)
        hasher.combine(fontWeight)
        hasher.combine(flags)
        hasher.combine(program)
    }
}
