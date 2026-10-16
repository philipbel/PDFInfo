internal import PDFEngineCore


public struct PDFFontDescriptorFlags: Sendable, OptionSet {
    public let rawValue: UInt32

    public static let fixedPitch = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_FIXED_PITCH.rawValue)
    public static let serif = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_SERIF.rawValue)
    public static let symbolic = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_SYMBOLIC.rawValue)
    public static let script = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_SCRIPT.rawValue)
    public static let nonSymbolic = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_NON_SYMBOLIC.rawValue)
    public static let italic = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_ITALIC.rawValue)
    public static let allCap = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_ALL_CAP.rawValue)
    public static let smallCap = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_SMALL_CAP.rawValue)
    public static let forceBold = PDFFontDescriptorFlags(rawValue: PDF_FONT_DESCRIPTOR_FLAG_FORCE_BOLD.rawValue)

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public struct PDFFontDescriptor: Sendable {
    public let name: String
    public let family: String?
    public let weight: Int?
    public let flags: PDFFontDescriptorFlags
    public let program: PDFFontProgram?
    public let descendantSubtype: PDFFontSubtype?

    internal init(descriptor: OpaquePointer) {
        // Name should always be present...
        name = pdf_font_descriptor_get_name(descriptor).flatMap { String(validatingCString: $0) } ?? ""
        family = pdf_font_descriptor_get_family(descriptor).flatMap { String(validatingCString: $0) }
        weight = pdf_font_descriptor_get_weight(descriptor).map { Int($0.pointee) }
        flags = PDFFontDescriptorFlags(rawValue: pdf_font_descriptor_get_flags(descriptor))
        program = pdf_font_descriptor_get_program(descriptor).map { PDFFontProgram(program: $0) }
        let descendantSubtypePtr = pdf_font_descriptor_get_descendant_subtype(descriptor)
        descendantSubtype = descendantSubtypePtr.map { PDFFontSubtype(subtype: $0.pointee) }
    }
}
