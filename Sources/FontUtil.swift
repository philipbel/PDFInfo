import Cocoa
import Foundation
import PDFKitExt


struct FontUtil {
    static func getSystemFont(named name: String, size: CGFloat) -> NSFont? {
        // 1. As given: PostScript name or family
        if let f = NSFont(name: name, size: size) {
            return f
        }

        // TODO: Other suffixes to support? Encountered this with IBM Plex fonts.
        // 2. "<Family> Regular", drop the Regular part
        if name.hasSuffix(" Regular") {
            let family = String(name.dropLast(" Regular".count))
            if let f = NSFont(name: family, size: size) {
                return f
            }
            // 3. family name only, resolve to a concrete member via descriptor
            let desc = NSFontDescriptor(fontAttributes: [.family: family])
            if let f = NSFont(descriptor: desc, size: size) {
                return f
            }
        }
        return nil
    }

    static func typeString(for font: any PDFFont) -> String {
        // See https://gitlab.freedesktop.org/poppler/poppler/-/blob/master/utils/pdffonts.cc?ref_type=heads#L43 and
        // Section 9.5 of ISO-32000-2 (PDF-2.0)
        switch font {
        case let type0Font as PDFType0Font:
            var s = PDFFontSubtype.type0.displayName
            let descendandSubtype = type0Font.descendant.subtype
            s += " ("
            s += descendandSubtype.displayName
            if let programKind = type0Font.descendant.descriptor?.program?.kind {
                s += "/"
                s += programKind.displayName
            }
            s += ")"
            return s
        case let programFont as any PDFProgramFont:
            var s = programFont.subtype.displayName
            if let programKind = programFont.descriptor?.program?.kind {
                s += " ("
                s += programKind.displayName
                s += ")"
            }
            return s
        default:
            return font.subtype.displayName
        }
    }

}
