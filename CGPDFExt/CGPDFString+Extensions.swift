public import CoreGraphics

public extension CGPDFStringRef {
    var string: String? {
        String(pdfString: self)
    }
}


public extension String {
    init?(pdfString: CGPDFStringRef?) {
        guard let pdfString,
              let string = CGPDFStringCopyTextString(pdfString) else {
            return nil
        }
        self = string as String
    }
}
