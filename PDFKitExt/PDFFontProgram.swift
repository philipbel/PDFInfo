internal import Foundation
internal import CoreGraphics
internal import OSLog

fileprivate let logger = Logger(subsystem: "PDFKitExt", category: String(describing: PDFFontProgram.self))


internal struct PDFFontProgram {
    var data: Data
    var kind: PDFFontProgramKind

    init?(fromFontDescriptorDictionary fontDescriptorDictionary: CGPDFDictionaryRef) throws {
        if let stream = fontDescriptorDictionary.stream(forKey: "FontFile") {
            guard let data = stream.data else {
                let msg = "'FontFile' has no data"
                logger.error("init(): \(msg)")
                throw PDFKitError.corruptedObject(message: msg)
            }
            self.data = data
            self.kind = .type1
        } else if let stream = fontDescriptorDictionary.stream(forKey: "FontFile2") {
            guard let data = stream.data else {
                let msg = "'FontFile2' has no data"
                logger.error("init(): \(msg)")
                throw PDFKitError.corruptedObject(message: msg)
            }
            self.data = data
            self.kind = .trueType
        } else if let stream = fontDescriptorDictionary.stream(forKey: "FontFile3") {
            guard let dict = stream.dictionary else {
                let msg = "'FontFile3' has no dictionary"
                logger.error("init(): \(msg)")
                throw PDFKitError.corruptedObject(message: msg)
            }
            guard let subtype = dict.name(forKey: "Subtype") else {
                let msg = "'FontFile3' dictionary has no 'Subtype'"
                logger.error("init(): \(msg)")
                throw PDFKitError.corruptedObject(message: msg)
            }
            guard let data = stream.data else {
                let msg = "'FontFile3' has no data"
                logger.error("init(): \(msg)")
                throw PDFKitError.corruptedObject(message: msg)
            }
            switch subtype {
            case "Type1C":
                kind = .type1C
            case "CIDFontType0C":
                kind = .cidFontType0C
            case "OpenType":
                kind = .openType
            default:
                let msg = "'FontFile3' has invalid subtype '\(subtype)'"
                logger.error("init(): \(msg)")
                throw PDFKitError.corruptedObject(message: msg)
            }
            self.data = data
        } else {
            logger.debug("init(): No font program found in font descriptor")
            return nil
        }
    }
}


// MARK: CustomDebugStringConvertible

extension PDFFontProgram: CustomDebugStringConvertible {
    var debugDescription: String {
        "PDFFontProgram(kind: \(kind), data: \(data.count) byte(s))"
    }
}


// MARK: Hashable

extension PDFFontProgram: Hashable {
}

