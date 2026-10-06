// See Table 120 (FontDescriptor fields)
public enum PDFFontProgramKind: String, Sendable, Codable {
    // FontFile, A stream containing a Type 1 font program
    case type1 = "type1"
    // FontFile2, A stream containing a TrueType font program
    case trueType = "trueType"
    // FontFile3, Subtype Type1C: Type 1–equivalent font program represented in the Compact Font Format (CFF)
    case type1C = "type1C"
    // FontFile3, Subtype CIDFontType0C: Type 0 CIDFont program represented in the Compact Font Format (CFF)
    case cidFontType0C = "cidFontType0C"
    // FontFile3, Subtype OpenType: OpenType font program
    // - A TrueType font dictionary or a CIDFontType2 CIDFont dictionary, if the embedded font program contains a "glyf"
    //   table
    // - A CIDFontType0 CIDFont dictionary, if the embedded font program contains a "CFF " table with a Top DICT that
    //   uses CIDFont operators (this is equivalent to subtype CIDFontType0C)
    // - A Type1 font dictionary or CIDFontType0 CIDFont dictionary, if the embedded font program contains a "CFF "
    //   table without CIDFont operators
    case openType = "openType"

    public var displayName: String {
        switch self {
        case .type1:
            String(localized: "Type 1", bundle: #bundle)
        case .trueType:
            String(localized: "TrueType", bundle: #bundle)
        case .type1C:
            String(localized: "Type 1C", bundle: #bundle)
        case .cidFontType0C:
            String(localized: "CID Type 0C", bundle: #bundle)
        case .openType:
            String(localized: "OpenType", bundle: #bundle)
        }
    }
}
