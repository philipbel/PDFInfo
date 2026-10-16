import Cocoa
import Foundation
import PDFEngine
import FontLocator


enum FontUtil {
    static func getSystemFont(for font: PDFFont, size: CGFloat) -> NSFont? {
        guard let displayName = font.displayName else {
            return nil
        }
        return getSystemFont(named: displayName, size: size)
    }

    static func getSystemFont(named name: String, size: CGFloat) -> NSFont? {
        guard let fontInfo = FontInfo(fontNamed: name) else {
            return nil
        }
        return NSFont(name: fontInfo.postscriptName, size: size)
    }

    static func buildPreviewFont(
        from pdfFont: PDFFont, size previewFontSize: CGFloat
    ) -> (isSystemFont: Bool, previewFont: NSFont?) {
        guard let displayName = pdfFont.displayName else {
            return (isSystemFont: false, previewFont: nil)
        }
        if let systemFont = FontUtil.getSystemFont(named: displayName, size: previewFontSize) {
            return (isSystemFont: true, previewFont: systemFont)
        }
        guard let program = pdfFont.descriptor?.program,
              let data = program.data else {
            return (isSystemFont: false, previewFont: nil)
        }

        guard let provider = CGDataProvider(data: data as CFData) else {
            return (isSystemFont: false, previewFont: nil)
        }
        guard let cgFont = CGFont(provider) else {
            return (isSystemFont: false, previewFont: nil)
        }
        let ctFont = CTFontCreateWithGraphicsFont(cgFont, previewFontSize, nil, nil)
        return (isSystemFont: false, ctFont as NSFont)
    }
}
