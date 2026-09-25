internal import Foundation
internal import CoreGraphics

public class PDFType3Font: PDFProgramFont {
    public override var debugDescription: String {
        "PDFType3Font(\(super.debugDescription)"
    }

    internal override init(from fontDictionary: CGPDFDictionaryRef) throws {
        try super.init(from: fontDictionary)
        try validateSubtype(expected: [.type3])
    }
}
