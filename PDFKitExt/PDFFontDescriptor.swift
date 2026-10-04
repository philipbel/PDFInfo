internal import Foundation
internal import CoreGraphics
private import OSLog


fileprivate let logger = Logger(subsystem: "PDFKitExt", category: String(describing: PDFFontDescriptor.self))


public struct PDFFontDescriptor: Identifiable {
    public struct Flags: OptionSet, Sendable {
        public var rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let fixedPitch = Flags(rawValue: 1 << 1)
        public static let serif = Flags(rawValue: 1 << 2)
        public static let symbolic = Flags(rawValue: 1 << 3)
        public static let script = Flags(rawValue: 1 << 4)
        public static let nonSymbolic = Flags(rawValue: 1 << 6)
        public static let italic = Flags(rawValue: 1 << 7)
        public static let allCap = Flags(rawValue: 1 << 17)
        public static let smallCap = Flags(rawValue: 1 << 18)
        public static let forceBold = Flags(rawValue: 1 << 19)

        public var displayDictionary: [String: Bool] {
            [
                String(localized: "Fixed Pitch", bundle: #bundle): contains(.fixedPitch),
                String(localized: "Serif", bundle: #bundle): contains(.serif),
                String(localized: "Symbolic", bundle: #bundle): contains(.symbolic),
                String(localized: "Script", bundle: #bundle): contains(.script),
                String(localized: "Non-symbolic", bundle: #bundle): contains(.nonSymbolic),
                String(localized: "Italic", bundle: #bundle): contains(.italic),
                String(localized: "All Cap", bundle: #bundle): contains(.allCap),
                String(localized: "Small Cap", bundle: #bundle): contains(.smallCap),
                String(localized: "Force Bold", bundle: #bundle): contains(.forceBold),
            ]
        }
    }

    public let name: String
    public let fontFamily: String?
    public let fontWeight: Int?
    public let flags: Flags
    public let program: PDFFontProgram?
    public let id: String

    internal init(from fontDescriptorDictionary: CGPDFDictionaryRef) throws {
        let type = fontDescriptorDictionary.name(forKey: "Type")
        guard let type else {
            let msg = "'FontDescriptor' has no 'Type'"
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
        self.flags = Flags(rawValue: UInt32(truncatingIfNeeded: flags))
        self.program = try PDFFontProgram(fromFontDescriptorDictionary: fontDescriptorDictionary)
        self.id = "\(name)-\(String(describing: fontFamily))-\(String(describing: fontWeight))-\(flags)-\(String(describing: program?.id))"
    }
}
