public import CoreGraphics

public extension CGPDFObjectRef {
    var type: CGPDFObjectType {
        CGPDFObjectGetType(self)
    }

    func asNull() throws -> Any? {
        guard type == .null else {
            throw CGPDFError.typeError(message: "Expected .null, got \(type)")
        }
        return nil
    }

    func asBool() throws -> Bool? {
        try Self.verifyTypes(expected: .boolean, actual: type)
        var boolean: CGPDFBoolean?
        guard CGPDFObjectGetValue(self, .boolean, &boolean),
              let boolean else {
            return nil
        }
        return boolean != 0
    }

    func asInt() throws -> Int? {
        try Self.verifyTypes(expected: .integer, actual: type)
        var integer: CGPDFInteger?
        guard CGPDFObjectGetValue(self, .integer, &integer),
              let integer else {
            return nil
        }
        return integer
    }

    func asReal() throws -> CGFloat? {
        try Self.verifyTypes(expected: .real, actual: type)
        var float: CGFloat?
        guard CGPDFObjectGetValue(self, .real, &float),
              let float else {
            return nil
        }
        return float
    }

    func asName() throws -> String? {
        try Self.verifyTypes(expected: .name, actual: type)
        var name: UnsafePointer<CChar>?
        guard CGPDFObjectGetValue(self, .name, &name),
              let name else {
            return nil
        }
        return String(cString: name)
    }

    func asString() throws -> String? {
        try Self.verifyTypes(expected: .string, actual: type)
        var stringRef: CGPDFStringRef?
        guard CGPDFObjectGetValue(self, .string, &stringRef),
              let stringRef else {
            return nil
        }
        return String(pdfString: stringRef)
    }

    func asArray() throws -> CGPDFArrayRef? {
        try Self.verifyTypes(expected: .array, actual: type)
        var array: CGPDFArrayRef?
        guard CGPDFObjectGetValue(self, .array, &array),
              let array else {
            return nil
        }
        return array
    }

    func asDictionary() throws -> CGPDFDictionaryRef? {
        try Self.verifyTypes(expected: .dictionary, actual: type)
        var dictionary: CGPDFDictionaryRef?
        guard CGPDFObjectGetValue(self, .dictionary, &dictionary),
              let dictionary else {
            return nil
        }
        return dictionary
    }

    func asStream() throws -> CGPDFStreamRef? {
        try Self.verifyTypes(expected: .stream, actual: type)
        var stream: CGPDFStreamRef?
        guard CGPDFObjectGetValue(self, .stream, &stream),
              let stream else {
            return nil
        }
        return stream
    }

    private static func verifyTypes(expected expectedType: CGPDFObjectType, actual actualType: CGPDFObjectType) throws {
        if expectedType != actualType {
            throw CGPDFError.typeError(message: "Invalid CGPDF type: expected \(expectedType), got \(actualType)")
        }
    }
}
