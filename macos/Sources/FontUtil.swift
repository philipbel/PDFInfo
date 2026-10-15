import Cocoa
import Foundation
import PDFKitExt


enum FontUtil {
    static func getSystemFont(named name: String, size: CGFloat) -> NSFont? {
        // 1. As given: PostScript name or family
        if let f = NSFont(name: name, size: size) {
            return f
        }

        // TODO: Other suffixes to support? Encountered this with IBM Plex fonts.
        // 2. "<Family> Regular", drop the Regular part
        if name.hasSuffix(" Regular") {
            let family = String(name.dropLast(" Regular".count))
            if let f = NSFont(name: family, size: size),
               f.familyName == family {
                return f
            }
            // 3. family name only, resolve to a concrete member via descriptor
            let desc = NSFontDescriptor(fontAttributes: [.family: family])
            if let f = NSFont(descriptor: desc, size: size),
               f.familyName == family {
                return f
            }
        }
        return nil
    }

    static func descriptor(from pdfFont: any PDFFont) -> PDFFontDescriptor? {
        return (pdfFont as? PDFType0Font)?.descendant.descriptor
        ?? (pdfFont as? any PDFProgramFont)?.descriptor
    }

    static func program(from pdfFont: any PDFFont) -> PDFFontProgram? {
        return descriptor(from: pdfFont)?.program
    }

    static func buildPreviewFont(
        from pdfFont: any PDFFont, size previewFontSize: CGFloat
    ) -> (isSystemFont: Bool, previewFont: NSFont?) {
        if let systemFont = FontUtil.getSystemFont(named: pdfFont.displayName, size: previewFontSize) {
            return (isSystemFont: true, previewFont: systemFont)
        }
        guard let program = program(from: pdfFont) else {
            return (isSystemFont: false, previewFont: nil)
        }

        guard let provider = CGDataProvider(data: program.data as CFData) else {
            return (isSystemFont: false, previewFont: nil)
        }
        guard let cgFont = CGFont(provider) else {
            return (isSystemFont: false, previewFont: nil)
        }
        let ctFont = CTFontCreateWithGraphicsFont(cgFont, previewFontSize, nil, nil)
        return (isSystemFont: false, ctFont as NSFont)
    }

    static func flagsString(from pdfFont: any PDFFont) -> String {
        guard let descriptor = descriptor(from: pdfFont) else {
            return ""
        }
        return descriptor.flags.displayDictionary.compactMap { key, value in
            value ? key : nil
        }
        .sorted()
        .joined(separator: ", ")
    }

    static nonisolated func typeString(for font: any PDFFont) -> String {
        // See https://gitlab.freedesktop.org/poppler/poppler/-/blob/master/poppler/GfxFont.cc#L288 and
        // Section 9.5 of ISO-32000-2 (PDF-2.0)
        if let type0Font = font as? PDFType0Font {
            return typeString(for: type0Font.descendant)
        } else if let programFont = font as? any PDFProgramFont {
            let programKind = programFont.descriptor?.program?.kind

            switch font.subtype {
            case .type1, .mmType1:
                switch programKind {
                case .none, .type1:
                    return String(localized: "Type 1")
                case .type1C:
                    return String(localized: "Type 1C")
                case .openType:
                    return String(localized: "Type 1C (OT)")
                default:
                    break
                }
            case .type3:
                return String(localized: "Type 3")
            case .trueType:
                switch programKind {
                case .none, .trueType:
                    return String(localized: "TrueType")
                case .openType:
                    return String(localized: "TrueType (OT)")
                default:
                    break
                }
            case .cidFontType0:
                switch programKind {
                case .none:
                    return String(localized: "CID Type 0")
                case .cidFontType0C:
                    return String(localized: "CID Type 0C")
                case .openType:
                    return String(localized: "CID Type 0C (OT)")
                default:
                    break
                }
            case .cidFontType2:
                switch programKind {
                case .none, .trueType:
                    return String(localized: "CID TrueType")
                case .openType:
                    return String(localized: "CID TrueType (OT)")
                default:
                    break
                }
            default:
                break
            }
            if let programKind {
                return "\(font.subtype.displayName) (\(programKind.displayName))"
            } else {
                return "\(font.subtype.displayName)"
            }
        } else {
            return font.subtype.displayName
        }
    }
}
