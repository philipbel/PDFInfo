// Copyright (c) 2026 Philip B. (philipbel)
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import PDFEngine
import Foundation


extension PDFFontDescriptorFlags: Localizable {
    private static let displayDictionary: [PDFFontDescriptorFlags: String] = [
        PDFFontDescriptorFlags.fixedPitch: String(localized: "Fixed Pitch", bundle: #bundle),
        PDFFontDescriptorFlags.serif: String(localized: "Serif", bundle: #bundle),
        PDFFontDescriptorFlags.symbolic: String(localized: "Symbolic", bundle: #bundle),
        PDFFontDescriptorFlags.script: String(localized: "Script", bundle: #bundle),
        PDFFontDescriptorFlags.nonSymbolic: String(localized: "Non-Symbolic", bundle: #bundle),
        PDFFontDescriptorFlags.italic: String(localized: "Italic", bundle: #bundle),
        PDFFontDescriptorFlags.allCap: String(localized: "All Cap", bundle: #bundle),
        PDFFontDescriptorFlags.smallCap: String(localized: "Small Cap", bundle: #bundle),
        PDFFontDescriptorFlags.forceBold: String(localized: "Force Bold", bundle: #bundle),
    ]

    public var localizedString: String {
        Self.displayDictionary.compactMap { flag, string in
            self.contains(flag) ? string : nil
        }
        .sorted()
        .joined(separator: ", ")
    }
}
