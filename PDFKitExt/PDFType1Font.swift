internal import Foundation
internal import CoreGraphics

public class PDFType1Font: PDFProgramFont {
    public override var debugDescription: String {
        "PDFType1Font(\(super.debugDescription)"
    }

    internal override init(from fontDictionary: CGPDFDictionaryRef) throws {
        try super.init(from: fontDictionary)
        try validateSubtype(expected: [.type1, .mmType1])
    }
}
