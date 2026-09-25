public import CoreGraphics

public extension CGPDFArrayRef {
    var count: Int {
        CGPDFArrayGetCount(self)
    }

    func hasNull(at index: Int) -> Bool {
        CGPDFArrayGetNull(self, index)
    }

    func object(at index: Int) -> CGPDFObjectRef? {
        var obj: CGPDFObjectRef?
        guard CGPDFArrayGetObject(self, index, &obj) else {
            return nil
        }
        return obj
    }

    func boolean(at index: Int) -> Bool? {
        var boolean: CGPDFBoolean = 0
        guard CGPDFArrayGetBoolean(self, index, &boolean) else {
            return nil
        }
        return boolean != 0
    }

    func integer(at index: Int) -> Int? {
        var integer: CGPDFInteger = 0
        guard CGPDFArrayGetInteger(self, index, &integer) else {
            return nil
        }
        return integer
    }

    func number(at index: Int) -> CGFloat? {
        var number: CGFloat = 0
        guard CGPDFArrayGetNumber(self, index, &number) else {
            return nil
        }
        return number
    }

    func name(at index: Int) -> String? {
        var name: UnsafePointer<CChar>?
        guard CGPDFArrayGetName(self, index, &name),
              let name else {
            return nil
        }
        return String(cString: name)
    }

    func string(at index: Int) -> String? {
        var stringRef: CGPDFStringRef?
        guard CGPDFArrayGetString(self, index, &stringRef),
              let stringRef else {
            return nil
        }
        return String(pdfString: stringRef)
    }

    func array(at index: Int) -> CGPDFArrayRef? {
        var array: CGPDFArrayRef?
        guard CGPDFArrayGetArray(self, index, &array),
              let array else {
            return nil
        }
        return array
    }

    func dictionary(at index: Int) -> CGPDFDictionaryRef? {
        var dictionary: CGPDFDictionaryRef?
        guard CGPDFArrayGetDictionary(self, index, &dictionary),
              let dictionary else {
            return nil
        }
        return dictionary
    }

    func stream(at index: Int) -> CGPDFStreamRef? {
        var stream: CGPDFStreamRef?
        guard CGPDFArrayGetStream(self, index, &stream),
              let stream else {
            return nil
        }
        return stream
    }
}
