public enum PDFFontSubtype: String, Sendable, Codable {
    case type0 = "Type0"
    case type1 = "Type1"
    case mmType1 = "MMType1"
    case type3 = "Type3"
    case trueType = "TrueType"
    case cidFontType0 = "CIDFontType0"
    case cidFontType2 = "CIDFontType2"

    public var displayName: String {
        switch self {
        case .type0:
            String(localized: "Type 0", bundle: #bundle)
        case .type1:
            String(localized: "Type 1", bundle: #bundle)
        case .mmType1:
            String(localized: "Type 1 (MM)", bundle: #bundle)
        case .type3:
            String(localized: "Type 3", bundle: #bundle)
        case .trueType:
            String(localized: "TrueType", bundle: #bundle)
        case .cidFontType0:
            String(localized: "CID Type 0", bundle: #bundle)
        case .cidFontType2:
            String(localized: "CID Type 2", bundle: #bundle)
        }
    }
}


// MARK: CustomStringConvertible

extension PDFFontSubtype: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
