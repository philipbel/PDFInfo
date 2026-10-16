internal import PDFEngineCore


public enum PDFFontSubtype: Sendable {
    case type0
    case type1
    case mmType1
    case type3
    case trueType
    case cidFontType0
    case cidFontType2

    internal init(subtype: pdf_font_subtype) {
        self = switch subtype {
        case PDF_FONT_SUBTYPE_TYPE0: .type0
        case PDF_FONT_SUBTYPE_TYPE1: .type1
        case PDF_FONT_SUBTYPE_MM_TYPE1: .mmType1
        case PDF_FONT_SUBTYPE_TYPE3: .type3
        case PDF_FONT_SUBTYPE_TRUETYPE: .trueType
        case PDF_FONT_SUBTYPE_CID_FONT_TYPE0: .cidFontType0
        case PDF_FONT_SUBTYPE_CID_FONT_TYPE2: .cidFontType2
        default:
            fatalError("Unrecognized font subtype \(subtype)")
        }
    }
}


public enum PDFFontDisplayType: Sendable {
    case type0
    case type1
    case type1c
    case type1cOpenType
    case type3
    case trueType
    case trueTypeOpenType
    case cidType0
    case cidType0c
    case cidType0cOpenType
    case cidTrueType
    case cidTrueTypeOpenType

    internal init(displayType: pdf_font_display_type) {
        self = switch displayType {
        case PDF_FONT_DISPLAY_TYPE_TYPE0: .type0
        case PDF_FONT_DISPLAY_TYPE_TYPE1: .type1
        case PDF_FONT_DISPLAY_TYPE_TYPE1C: .type1c
        case PDF_FONT_DISPLAY_TYPE_TYPE1C_OPEN_TYPE: .type1cOpenType
        case PDF_FONT_DISPLAY_TYPE_TYPE3: .type3
        case PDF_FONT_DISPLAY_TYPE_TRUE_TYPE: .trueType
        case PDF_FONT_DISPLAY_TYPE_TRUE_TYPE_OPEN_TYPE: .trueTypeOpenType
        case PDF_FONT_DISPLAY_TYPE_CID_TYPE0: .cidType0
        case PDF_FONT_DISPLAY_TYPE_CID_TYPE0C: .cidType0c
        case PDF_FONT_DISPLAY_TYPE_CID_TYPE0C_OPEN_TYPE: .cidType0cOpenType
        case PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE: .cidTrueType
        case PDF_FONT_DISPLAY_TYPE_CID_TRUE_TYPE_OPEN_TYPE: .cidTrueTypeOpenType
        default:
            fatalError("Unrecognized font display type \(displayType)")
        }
    }
}


public struct PDFFont: Identifiable, Sendable {
    public let id: UInt64
    public let subtype: PDFFontSubtype
    public let displayName: String?
    public let baseFont: String?
    public let isSubset: Bool
    public let isEmbedded: Bool
    public let cmapName: String?
    public let descriptor: PDFFontDescriptor?
    public let displayType: PDFFontDisplayType

    internal init(font: OpaquePointer) {
        id = pdf_font_get_id(font)
        subtype = PDFFontSubtype(subtype: pdf_font_get_subtype(font))
        displayName = pdf_font_get_display_name(font).flatMap { String(validatingCString: $0) }
        baseFont = pdf_font_get_base_font(font).flatMap { String(validatingCString: $0) }
        isSubset = pdf_font_is_subset(font)
        isEmbedded = pdf_font_is_embedded(font)
        cmapName = pdf_font_get_cmap_name(font).flatMap { String(validatingCString: $0) }
        descriptor = pdf_font_get_descriptor(font).flatMap { PDFFontDescriptor(descriptor: $0) }
        displayType = PDFFontDisplayType(displayType: pdf_font_get_display_type(font))
    }
}
