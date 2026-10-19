// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import PDFEngine
import Foundation

extension PDFFontDisplayType: Localizable {
    public var localizedString: String {
        switch self {
        case .type0: String(localized: "Type 0")
        case .type1: String(localized: "Type 1")
        case .type1c: String(localized: "Type 1C")
        case .type1cOpenType: String(localized: "Type 1C (OpenType)")
        case .type3: String(localized: "Type 3")
        case .trueType: String(localized: "TrueType")
        case .trueTypeOpenType: String(localized: "TrueType (OpenType)")
        case .cidType0: String(localized: "CID Type 0")
        case .cidType0c: String(localized: "CID Type 0C")
        case .cidType0cOpenType: String(localized: "CID Type 0C (OpenType)")
        case .cidTrueType: String(localized: "CID TrueType")
        case .cidTrueTypeOpenType: String(localized: "CID TrueType (OpenType)")
        @unknown default: ""
        }
    }
}
