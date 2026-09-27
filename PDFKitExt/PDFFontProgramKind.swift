// See Table 120 (FontDescriptor fields)
public enum PDFFontProgramKind: String, Sendable, Codable {
    case type1 = "type1" // FontFile
    case trueType = "trueType" // FontFile2
    // FontFile3, Subtype Type1C: Type 1–equivalent font program represented in the Compact Font Format (CFF)
    case type1C = "type1C"
    // FontFile3, Subtype CIDFontType0C: Type 0 CIDFont program represented in the Compact Font Format (CFF)
    case cidFontType0C = "cidFontType0C"
    // FontFile3, Subtype OpenType: OpenType font program, as described in ISO/IEC 14496-22, Compact Font Format (CFF)
    case openType = "OpenType"

    public var displayName: String {
        switch self {
        case .type1:
            String(localized: "Type1", bundle: #bundle)
        case .trueType:
            String(localized: "TrueType", bundle: #bundle)
        case .type1C:
            String(localized: "Type1C", bundle: #bundle)
        case .cidFontType0C:
            String(localized: "CID Type0C", bundle: #bundle)
        case .openType:
            String(localized: "OpenType", bundle: #bundle)
        }
    }
}
