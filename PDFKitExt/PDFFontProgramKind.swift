// See Table 120 (FontDescriptor fields)
public enum PDFFontProgramKind: String, Sendable {
    case type1 = "type1" // FontFile
    case trueType = "trueType" // FontFile2
    // FontFile3, Subtype Type1C: Type 1–equivalent font program represented in the Compact Font Format (CFF)
    case type1C = "type1C"
    // FontFile3, Subtype CIDFontType0C: Type 0 CIDFont program represented in the Compact Font Format (CFF)
    case cidFontType0C = "cidFontType0C"
    // FontFile3, Subtype OpenType: OpenType font program, as described in ISO/IEC 14496-22, Compact Font Format (CFF)
    case openType = "OpenType"
}
