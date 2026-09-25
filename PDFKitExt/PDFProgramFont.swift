internal import Foundation
internal import CoreGraphics


public class PDFProgramFont: PDFBaseFont {
    public var descriptor: PDFFontDescriptor?

    public var isEmbedded: Bool {
        descriptor?.program != nil
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)
        hasher.combine(descriptor)
    }

    public static func == (lhs: borrowing PDFProgramFont, rhs: borrowing PDFProgramFont) -> Bool {
        (lhs as PDFBaseFont) == (rhs as PDFBaseFont) && lhs.descriptor == rhs.descriptor
    }

    public override var debugDescription: String {
        "PDFProgramFont(\(super.debugDescription), descriptor: \(descriptor?.debugDescription ?? "null"))"
    }

    internal override init(from fontDictionary: CGPDFDictionaryRef) throws {
        try super.init(from: fontDictionary)
        if let fontDescriptorDict = fontDictionary.dictionary(forKey: "FontDescriptor") {
            self.descriptor = try PDFFontDescriptor(from: fontDescriptorDict)
        }
    }
}
