internal import Foundation
internal import CoreGraphics

public class PDFCIDFont: PDFProgramFont {
    internal override init(from fontDictionary: CGPDFDictionaryRef) throws {
        try super.init(from: fontDictionary)
        try validateSubtype(expected: [.cidFontType0, .cidFontType2])
    }

    public override var debugDescription: String {
        "PDFCIDFont(\(super.debugDescription)"
    }
}
