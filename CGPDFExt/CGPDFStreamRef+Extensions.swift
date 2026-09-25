public import CoreGraphics
public import Foundation

public extension CGPDFStreamRef {
    var dictionary: CGPDFDictionaryRef? {
        CGPDFStreamGetDictionary(self)
    }

    var data: Data? {
        var format: CGPDFDataFormat = .raw
        guard let cfData = CGPDFStreamCopyData(self, &format) else {
            return nil
        }
        return cfData as Data
    }
}
