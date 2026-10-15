public import CoreGraphics

public extension CGPDFDictionaryRef {
    var count: Int {
        CGPDFDictionaryGetCount(self)
    }

    func object(forKey key: String) -> CGPDFObjectRef? {
        var obj: CGPDFObjectRef?
        guard CGPDFDictionaryGetObject(self, key, &obj) else {
            return nil
        }
        return obj
    }

    func boolean(forKey key: String) -> Bool? {
        var boolean: CGPDFBoolean = 0
        guard CGPDFDictionaryGetBoolean(self, key, &boolean) else {
            return nil
        }
        return boolean != 0
    }

    func integer(forKey key: String) -> Int? {
        var integer: CGPDFInteger = 0
        guard CGPDFDictionaryGetInteger(self, key, &integer) else {
            return nil
        }
        return integer
    }

    func number(forKey key: String) -> CGFloat? {
        var number: CGFloat = 0
        guard CGPDFDictionaryGetNumber(self, key, &number) else {
            return nil
        }
        return number
    }

    func name(forKey key: String) -> String? {
        var name: UnsafePointer<CChar>?
        guard CGPDFDictionaryGetName(self, key, &name),
              let name else {
            return nil
        }
        return String(cString: name)
    }

    func string(forKey key: String) -> String? {
        var stringRef: CGPDFStringRef?
        guard CGPDFDictionaryGetString(self, key, &stringRef),
              let stringRef else {
            return nil
        }
        return String(pdfString: stringRef)
    }

    func array(forKey key: String) -> CGPDFArrayRef? {
        var array: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(self, key, &array),
              let array else {
            return nil
        }
        return array
    }

    func dictionary(forKey key: String) -> CGPDFDictionaryRef? {
        var dictionary: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(self, key, &dictionary),
              let dictionary else {
            return nil
        }
        return dictionary
    }

    func stream(forKey key: String) -> CGPDFStreamRef? {
        var stream: CGPDFStreamRef?
        guard CGPDFDictionaryGetStream(self, key, &stream),
              let stream else {
            return nil
        }
        return stream
    }

    func forEach(function: (_ key: String, _ object: CGPDFObjectRef) -> Void) {
        CGPDFDictionaryApplyBlock(self, { itemKeyPtr, itemValue, _ in
            let itemKey = String(cString: itemKeyPtr)
            function(itemKey, itemValue)
            return true
        }, nil)
    }

    func compactMap<T>(function: (_ key: String, _ object: CGPDFObjectRef) -> T?) -> [T] {
        var result: [T] = []
        CGPDFDictionaryApplyBlock(self, { itemKeyPtr, itemValue, _ in
            let itemKey = String(cString: itemKeyPtr)
            if let value = function(itemKey, itemValue) {
                result.append(value)
            }
            return true
        }, nil)
        return result
    }
}
