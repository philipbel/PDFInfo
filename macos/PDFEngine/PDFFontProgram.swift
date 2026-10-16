public import Foundation
internal import PDFEngineCore


public enum PDFFontProgramKind: Sendable {
    case type1
    case trueType
    case type1c
    case cidFontType0c
    case openType

    internal init(kind: pdf_font_program_kind) {
        self = switch kind {
        case PDF_FONT_PROGRAM_KIND_TYPE1: .type1
        case PDF_FONT_PROGRAM_KIND_TRUE_TYPE: .trueType
        case PDF_FONT_PROGRAM_KIND_TYPE1C: .type1c
        case PDF_FONT_PROGRAM_KIND_CID_FONT_TYPE0C: .cidFontType0c
        case PDF_FONT_PROGRAM_KIND_OPEN_TYPE: .openType
        default:
            fatalError("Unrecognized program kind \(kind)")
        }
    }
}


public struct PDFFontProgram: Sendable {
    public let kind: PDFFontProgramKind
    public let data: Data?

    internal init(program: OpaquePointer) {
        kind = .init(kind: pdf_font_program_get_kind(program))
        let size = pdf_font_program_get_size(program)
        data = pdf_font_program_get_data(program).map { Data(bytes: $0, count: size) }
    }
}
