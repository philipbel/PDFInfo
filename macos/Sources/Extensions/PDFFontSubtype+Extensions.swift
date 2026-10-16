import Foundation
import PDFEngine


extension PDFFontSubtype: Localizable {
    public var localizedString: String {
        switch self {
        case .type0: String(localized: "Type 0")
        case .type1: String(localized: "Type 1")
        case .mmType1: String(localized: "MM Type 1")
        case .type3: String(localized: "Type 3")
        case .trueType: String(localized: "TrueType")
        case .cidFontType0: String(localized: "CID Font Type 0")
        case .cidFontType2: String(localized: "CID Font Type 2")
        @unknown default:
            ""
        }
    }
}
