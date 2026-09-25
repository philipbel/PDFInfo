public enum PDFFontSubtype: String, Sendable {
    case type0 = "Type0"
    case type1 = "Type1"
    case mmType1 = "MMType1"
    case type3 = "Type3"
    case trueType = "TrueType"
    case cidFontType0 = "CIDFontType0"
    case cidFontType2 = "CIDFontType2"
}


// MARK: CustomStringConvertible

extension PDFFontSubtype: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
