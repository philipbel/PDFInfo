internal import Foundation
internal import CoreGraphics

public class PDFTrueTypeFont: PDFProgramFont {
    public override var debugDescription: String {
        "PDFTrueTypeFont(\(super.debugDescription))"
    }

    internal override init(from fontDictionary: CGPDFDictionaryRef) throws {
        try super.init(from: fontDictionary)
        try validateSubtype(expected: [.trueType])
    }
}
